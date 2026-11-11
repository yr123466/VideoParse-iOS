import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
final class AppStore: ObservableObject {

    // MARK: 状态定义

    enum ParseState {
        case idle
        case loading
        case success(ParseResponse)
        case failure(String)
    }

    enum ApiStatus {
        case idle
        case checking
        case success(Int)
        case failure(String)
    }

    enum UpdateState {
        case idle
        case checking
        case upToDate(String)
        case failure(String)
    }

    // MARK: 常量

    static let appVersion = "1.0.0"
    static let appBuild = 1
    static let sponsorURL = "https://zs.69yr.cn"
    static let feedbackEmail = "3176210846@qq.com"

    private enum Keys {
        static let customApiKey = "custom_api_key"
        static let autoClipboard = "auto_parse_clipboard"
        static let preferHighQuality = "prefer_high_quality"
        static let disclaimerAccepted = "disclaimer_accepted"
    }

    // MARK: 已发布状态

    @Published var inputText: String = ""
    @Published var parseState: ParseState = .idle
    @Published var activeVideoUrl: String = ""
    @Published var activeQuality: String = ""

    @Published var history: [HistoryItem] = []
    @Published var searchQuery: String = ""
    @Published var selectedTab: Int = 0
    @Published var libraryTab: Int = 0
    @Published var platformFilter: String? = nil

    @Published var customApiKey: String = ""
    @Published var autoParseClipboard: Bool = true
    @Published var preferHighQuality: Bool = true

    @Published var disclaimerAccepted: Bool = false
    @Published var showDisclaimer: Bool = false
    @Published var isFirstLaunchDisclaimer: Bool = false

    @Published var apiStatus: ApiStatus = .idle
    @Published var updateState: UpdateState = .idle
    @Published var pendingUpdate: AppUpdateInfo? = nil
    @Published var showUpdate: Bool = false

    @Published var clipboardHint: Bool = false
    @Published var toast: String? = nil

    private var toastTask: Task<Void, Never>? = nil
    private let defaults = UserDefaults.standard

    // MARK: 初始化

    init() {
        customApiKey = defaults.string(forKey: Keys.customApiKey) ?? ""
        autoParseClipboard = defaults.object(forKey: Keys.autoClipboard) as? Bool ?? true
        preferHighQuality = defaults.object(forKey: Keys.preferHighQuality) as? Bool ?? true
        disclaimerAccepted = defaults.bool(forKey: Keys.disclaimerAccepted)
        isFirstLaunchDisclaimer = !disclaimerAccepted
        showDisclaimer = !disclaimerAccepted
        history = AppStore.loadHistory()

        Task {
            await refreshUpdate(manual: false)
        }
    }

    /// 内置密钥通过构建参数注入，不写死在源码里
    static func detectBuiltInKey() -> String {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "VideoParseAPIKey") as? String) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix("$(") { return "" }
        return trimmed
    }

    var effectiveKey: String {
        let custom = customApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? AppStore.detectBuiltInKey() : custom
    }

    var hasBuiltInKey: Bool { !AppStore.detectBuiltInKey().isEmpty }
    var hasCustomKey: Bool { !customApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    // MARK: 输入

    func setInput(_ text: String) {
        inputText = text
        clipboardHint = false
    }

    func clearInput() {
        inputText = ""
        parseState = .idle
    }

    func pasteFromClipboard() {
        if let text = Clipboard.read(), !text.isEmpty {
            inputText = text
            clipboardHint = false
            showToast("已粘贴剪贴板内容")
        } else {
            showToast("剪贴板中没有文字内容")
        }
    }

    /// 用户点击横幅后才真正读取剪贴板（避免每次启动弹系统粘贴授权）
    func applyClipboardSuggestion() {
        clipboardHint = false
        guard let text = Clipboard.read(), !text.isEmpty else {
            showToast("剪贴板中没有可用的链接")
            return
        }
        let url = AppStore.extractURL(text)
        guard url.lowercased().hasPrefix("http") else {
            showToast("剪贴板中没有识别到链接")
            return
        }
        inputText = url
        parse(url)
    }

    func dismissClipboardSuggestion() {
        clipboardHint = false
    }

    // MARK: 解析

    func parse(_ override: String? = nil) {
        let raw = (override ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            parseState = .failure("请输入或粘贴要解析的视频链接")
            return
        }
        let url = AppStore.extractURL(raw)
        guard url.lowercased().hasPrefix("http") else {
            parseState = .failure("请输入有效的网络链接地址 (http/https)")
            return
        }
        guard !effectiveKey.isEmpty else {
            parseState = .failure("未配置 API Key，请前往「设置 → API Key 密钥设置」填写后重试")
            return
        }

        parseState = .loading
        Task {
            do {
                let response = try await APIClient.parse(url: url, key: effectiveKey)
                guard response.code == 200, let data = response.data else {
                    throw APIError.message(response.errorText)
                }
                activeVideoUrl = data.primaryVideoUrl
                activeQuality = data.primaryQuality
                parseState = .success(response)
                storeHistory(response: response, data: data, input: raw, target: url)
            } catch {
                parseState = .failure(error.localizedDescription)
            }
        }
    }

    func retry() {
        if case .failure = parseState {
            parse()
        }
    }

    func selectQuality(_ item: VideoBackupItem) {
        guard let url = item.url, !url.isEmpty else { return }
        activeVideoUrl = url
        activeQuality = item.title
    }

    // MARK: 历史 / 素材库

    private func storeHistory(response: ParseResponse, data: ParseData, input: String, target: String) {
        let images = data.extractAllImages()
        let liveVideo = data.liveVideoUrl ?? ""
        let effectiveVideo = data.url ?? (liveVideo.isEmpty ? nil : liveVideo) ?? ""
        let hasImages = !images.isEmpty
        let isImagePost = hasImages && (effectiveVideo.isEmpty || data.type == "image" || data.type == "live" || images.count > 1)

        let mediaType: String
        if isImagePost || hasImages {
            mediaType = "image"
        } else if data.type == "audio" || (effectiveVideo.isEmpty && data.extractAudioUrl() != nil) {
            mediaType = "audio"
        } else {
            mediaType = "video"
        }

        var item = HistoryItem()
        item.originalInput = input
        item.targetUrl = target
        item.title = data.title ?? data.desc ?? "未命名作品"
        item.desc = data.desc ?? ""
        item.coverUrl = data.cover ?? images.first ?? ""
        item.videoUrl = effectiveVideo
        item.audioUrl = data.extractAudioUrl() ?? ""
        item.authorName = data.author?.name ?? "佚名"
        item.authorAvatar = data.author?.avatar ?? ""
        item.platform = response.platform ?? SupportedPlatforms.detect(target)
        item.mediaType = mediaType
        item.duration = data.duration ?? 0
        item.sizeLabel = data.sizeLabel ?? Fmt.size(data.size)
        item.quality = data.quality ?? data.label ?? "原画"
        item.images = images
        item.isFavorite = false
        item.timestamp = Date()

        history.insert(item, at: 0)
        if history.count > 300 { history = Array(history.prefix(300)) }
        saveHistory()
    }

    func saveAudioMaterial(title: String, author: String, audioUrl: String, coverUrl: String, platform: String, originalInput: String) {
        guard !audioUrl.isEmpty else { return }
        var item = HistoryItem()
        item.originalInput = originalInput
        item.targetUrl = audioUrl
        item.title = title.isEmpty ? "背景原声音乐" : title
        item.desc = "背景原声音乐 · \(author.isEmpty ? "未知作者" : author)"
        item.coverUrl = coverUrl
        item.videoUrl = ""
        item.audioUrl = audioUrl
        item.authorName = author.isEmpty ? "未知作者" : author
        item.authorAvatar = coverUrl
        item.platform = platform
        item.mediaType = "audio"
        item.sizeLabel = "MP3音频"
        item.quality = "高清音频"
        item.images = []
        item.timestamp = Date()
        history.insert(item, at: 0)
        saveHistory()
        showToast("已收录至素材库「背景音乐」")
    }

    func toggleFavorite(_ item: HistoryItem) {
        guard let idx = history.firstIndex(where: { $0.id == item.id }) else { return }
        history[idx].isFavorite.toggle()
        saveHistory()
        showToast(history[idx].isFavorite ? "已加入收藏" : "已取消收藏")
    }

    func delete(_ item: HistoryItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
        showToast("素材库已清空")
    }

    var filteredHistory: [HistoryItem] {
        history.filter { item in
            let matchesQuery: Bool
            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                matchesQuery = true
            } else {
                let q = searchQuery
                matchesQuery = item.title.localizedCaseInsensitiveContains(q)
                    || item.authorName.localizedCaseInsensitiveContains(q)
                    || item.platformName.localizedCaseInsensitiveContains(q)
            }

            let matchesTab: Bool
            switch libraryTab {
            case 1: matchesTab = item.mediaType == "video" && !item.isImageMedia
            case 2: matchesTab = item.mediaType != "audio" && item.isImageMedia
            case 3: matchesTab = item.mediaType == "audio" || (!item.audioUrl.isEmpty && item.videoUrl.isEmpty)
            case 4: matchesTab = item.isFavorite
            default: matchesTab = true
            }

            let matchesPlatform: Bool
            if let filter = platformFilter {
                if filter == "music" {
                    matchesPlatform = item.mediaType == "audio"
                } else {
                    matchesPlatform = item.platform.lowercased() == filter.lowercased()
                }
            } else {
                matchesPlatform = true
            }

            return matchesQuery && matchesTab && matchesPlatform
        }
    }

    var favoriteCount: Int { history.filter { $0.isFavorite }.count }

    var videoCount: Int { history.filter { $0.mediaType == "video" && !$0.isImageMedia }.count }
    var imageCount: Int { history.filter { $0.mediaType != "audio" && $0.isImageMedia }.count }
    var audioCount: Int { history.filter { $0.mediaType == "audio" }.count }

    private static var historyFileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("videoparse_history.json")
    }

    private static func loadHistory() -> [HistoryItem] {
        guard let data = try? Data(contentsOf: historyFileURL) else { return [] }
        return (try? JSONDecoder().decode([HistoryItem].self, from: data)) ?? []
    }

    func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: AppStore.historyFileURL, options: .atomic)
        } catch {
            print("save history failed: \(error)")
        }
    }

    // MARK: 设置

    func saveCustomKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        customApiKey = trimmed
        defaults.set(trimmed, forKey: Keys.customApiKey)
        showToast(trimmed.isEmpty ? "已恢复使用内置密钥" : "API Key 已保存")
    }

    func resetCustomKey() {
        customApiKey = ""
        defaults.removeObject(forKey: Keys.customApiKey)
        showToast("已恢复使用内置密钥")
    }

    func setAutoClipboard(_ enabled: Bool) {
        autoParseClipboard = enabled
        defaults.set(enabled, forKey: Keys.autoClipboard)
    }

    func setPreferHighQuality(_ enabled: Bool) {
        preferHighQuality = enabled
        defaults.set(enabled, forKey: Keys.preferHighQuality)
    }

    func acceptDisclaimer() {
        disclaimerAccepted = true
        defaults.set(true, forKey: Keys.disclaimerAccepted)
        showDisclaimer = false
    }

    func openDisclaimer() {
        isFirstLaunchDisclaimer = false
        showDisclaimer = true
    }

    func dismissDisclaimer() {
        if disclaimerAccepted { showDisclaimer = false }
    }

    // MARK: 剪贴板感知

    /// 使用系统 detectPatterns 静默探测（不读取内容、不触发粘贴授权弹窗）
    func checkClipboard() {
        guard autoParseClipboard else { return }
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasStrings else { return }
        pasteboard.detectPatterns(for: [.probableWebURL]) { result in
            guard case .success(let patterns) = result, !patterns.isEmpty else { return }
            Task { @MainActor in
                if self.inputText.isEmpty {
                    withAnimation(.easeOut(duration: 0.2)) { self.clipboardHint = true }
                }
            }
        }
    }

    // MARK: 网络诊断

    func testConnection() {
        apiStatus = .checking
        Task {
            do {
                let result = try await APIClient.status()
                apiStatus = .success(result.latency)
            } catch {
                apiStatus = .failure(error.localizedDescription)
            }
        }
    }

    // MARK: 检查更新

    func refreshUpdate(manual: Bool) async {
        if manual { updateState = .checking }
        do {
            guard let info = try await APIClient.checkUpdate() else {
                if manual { updateState = .upToDate("当前已是最新版本 (v\(AppStore.appVersion))") }
                return
            }
            if AppStore.isNewer(serverVersion: info.version, serverCode: info.versionCode) {
                pendingUpdate = info
                showUpdate = true
                updateState = .idle
            } else if manual {
                updateState = .upToDate("当前已是最新版本 (v\(AppStore.appVersion))")
            }
        } catch {
            if manual { updateState = .failure(error.localizedDescription) }
        }
    }

    func checkUpdateNow() {
        Task { await refreshUpdate(manual: true) }
    }

    private static func isNewer(serverVersion: String, serverCode: Int) -> Bool {
        if serverCode > AppStore.appBuild { return true }
        let server = serverVersion.split(separator: ".").compactMap { Int($0) }
        let current = AppStore.appVersion.split(separator: ".").compactMap { Int($0) }
        let count = max(server.count, current.count)
        for i in 0..<count {
            let s = i < server.count ? server[i] : 0
            let c = i < current.count ? current[i] : 0
            if s > c { return true }
            if s < c { return false }
        }
        return false
    }

    // MARK: 下载

    func downloadVideo(url: String, title: String) {
        guard !url.isEmpty, URL(string: url) != nil else {
            showToast("当前没有可下载的视频直链")
            return
        }
        let name = "\(DownloadManager.safeName(title.isEmpty ? "video" : title))_\(Int(Date().timeIntervalSince1970)).mp4"
        DownloadManager.shared.downloadSingle(url: url, filename: name, title: "下载无水印高清视频")
    }

    func downloadImage(url: String, title: String, index: Int = 1) {
        guard !url.isEmpty else { return }
        let ext = url.lowercased().contains(".png") ? "png" : "jpg"
        let name = "\(DownloadManager.safeName(title.isEmpty ? "image" : title))_\(index)_\(Int(Date().timeIntervalSince1970)).\(ext)"
        DownloadManager.shared.downloadSingle(url: url, filename: name, title: "下载图片")
    }

    func downloadAllImages(urls: [String], title: String) {
        guard !urls.isEmpty else { return }
        DownloadManager.shared.downloadBatch(urls: urls, baseTitle: title.isEmpty ? "图集" : title, ext: "jpg", title: "批量下载图集")
    }

    func downloadAudio(url: String, title: String) {
        guard !url.isEmpty else { return }
        let name = "\(DownloadManager.safeName(title.isEmpty ? "audio" : title))_\(Int(Date().timeIntervalSince1970)).m4a"
        DownloadManager.shared.downloadSingle(url: url, filename: name, title: "下载背景音乐")
    }

    func saveToAlbum(url: URL, isVideo: Bool) {
        Task {
            do {
                try await PhotoSaver.save(url: url, isVideo: isVideo)
                showToast("已保存到系统相册")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    // MARK: 工具

    func share(_ items: [Any]) {
        DownloadManager.shared.sharePayload = SharePayload(items: items)
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { toast = message }
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.2)) { self.toast = nil }
            }
        }
    }

    func openSponsor() {
        if let url = URL(string: AppStore.sponsorURL) {
            UIApplication.shared.open(url)
        }
    }

    /// 从混杂文本中提取第一个链接（支持中文口令）
    static func extractURL(_ text: String) -> String {
        let pattern = "https?://[A-Za-z0-9_.\\-]+(?:\\.[A-Za-z]{2,})+(?:/[^\\s一-龥]*)?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let matchRange = Range(match.range, in: text) {
            return String(text[matchRange])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func loadHistoryItem(_ item: HistoryItem) {
        inputText = item.targetUrl
        selectedTab = 0
        parse(item.targetUrl)
    }
}
