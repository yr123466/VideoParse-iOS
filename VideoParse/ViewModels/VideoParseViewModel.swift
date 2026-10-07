import Foundation
import Combine
import UIKit

// MARK: - UI 状态 (对应 Android ParseUiState / ApiStatusUiState / UpdateUiState)

enum ParseUiState {
    case idle
    case loading
    case success(response: ParseResponse, activeVideoUrl: String, activeQualityLabel: String)
    case error(String)
}

enum ApiStatusUiState {
    case idle
    case checking
    case success(latencyMs: Int, message: String)
    case error(String)
}

enum UpdateUiState {
    case idle
    case checking
    case available(AppUpdateInfo)
    case upToDate(String)
    case error(String)
}

// MARK: - 主 ViewModel (对应 Android VideoParseViewModel)

@MainActor
final class VideoParseViewModel: ObservableObject {

    private let repository = VideoParseRepository.shared
    private let settings = SettingsStore.shared

    // 解析输入与状态
    @Published var inputText: String = ""
    @Published var parseState: ParseUiState = .idle

    // 历史筛选
    @Published var searchQuery: String = ""
    @Published var historyTab: Int = 0          // 0 全部 / 1 收藏 / 2 视频 / 3 图集
    @Published var selectedPlatformFilter: String? = nil

    // API Key
    @Published var customApiKey: String = ""
    @Published var hasCustomApiKey: Bool = false
    @Published var apiStatusState: ApiStatusUiState = .idle

    // 剪贴板
    @Published var autoParseClipboard: Bool = true
    @Published var detectedClipboardUrl: String? = nil

    // 免责声明
    @Published var isDisclaimerAccepted: Bool = false
    @Published var showDisclaimerDialog: Bool = false
    @Published var declinedDisclaimer: Bool = false

    // 更新
    @Published var updateUiState: UpdateUiState = .idle
    @Published var showUpdateDialog: Bool = false
    @Published var currentUpdateInfo: AppUpdateInfo? = nil

    // 保存目录
    @Published var customSaveDirName: String = ""
    @Published var customSaveDirURL: URL? = nil

    // 历史数据
    @Published var allHistory: [ParseHistoryItem] = []

    // Toast
    @Published var toastMessage: String? = nil

    let feedbackEmail = SettingsStore.feedbackEmail
    let currentVersion = SettingsStore.appVersion

    private var cancellables = Set<AnyCancellable>()

    init() {
        customApiKey = settings.customApiKey ?? ""
        hasCustomApiKey = settings.hasCustomApiKey
        autoParseClipboard = settings.isAutoParseClipboard
        isDisclaimerAccepted = settings.isDisclaimerAccepted
        showDisclaimerDialog = !settings.isDisclaimerAccepted
        customSaveDirName = settings.customSaveDirName
        customSaveDirURL = settings.resolveCustomSaveDir()

        // 订阅历史数据变化
        repository.history.itemsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.allHistory = items
            }
            .store(in: &cancellables)

        // 剪贴板自动感知（对应 Android ON_RESUME 生命周期）
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkClipboard()
            }
            .store(in: &cancellables)

        // 启动时静默检查更新
        checkAppUpdate(manual: false)
    }

    // MARK: - 派生数据

    var filteredHistory: [ParseHistoryItem] {
        return allHistory.filter { item in
            let matchesQuery = searchQuery.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchQuery) ||
                item.authorName.localizedCaseInsensitiveContains(searchQuery) ||
                item.platform.localizedCaseInsensitiveContains(searchQuery)

            let matchesTab: Bool
            switch historyTab {
            case 1: matchesTab = item.isFavorite
            case 2: matchesTab = item.mediaType == "video"
            case 3: matchesTab = item.mediaType == "image"
            default: matchesTab = true
            }

            let matchesPlatform = selectedPlatformFilter == nil ||
                item.platform.caseInsensitiveCompare(selectedPlatformFilter ?? "") == .orderedSame

            return matchesQuery && matchesTab && matchesPlatform
        }
    }

    var favoriteCount: Int {
        return allHistory.filter { $0.isFavorite }.count
    }

    // MARK: - 输入

    func onInputChanged(_ text: String) { inputText = text }

    func clearInput() { inputText = "" }

    func pasteText(_ text: String) {
        inputText = text
        detectedClipboardUrl = nil
    }

    func dismissClipboardBanner() { detectedClipboardUrl = nil }

    private func checkClipboard() {
        guard autoParseClipboard else { return }
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        guard text.contains("http://") || text.contains("https://") else { return }
        let extracted = repository.extractUrl(text)
        guard !extracted.isEmpty, extracted != inputText else { return }
        detectedClipboardUrl = extracted
    }

    // MARK: - 筛选

    func setSearchQuery(_ query: String) { searchQuery = query }
    func setHistoryTab(_ tab: Int) { historyTab = tab }
    func setPlatformFilter(_ platform: String?) { selectedPlatformFilter = platform }

    // MARK: - 解析

    func parse(urlOverride: String? = nil) {
        let target = urlOverride ?? inputText
        guard !target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            parseState = .error("请输入或粘贴要解析的视频链接")
            return
        }

        parseState = .loading
        Task {
            do {
                let response = try await repository.parseVideo(input: target)
                guard let data = response.data else {
                    parseState = .error(response.errorMessage)
                    return
                }
                parseState = .success(
                    response: response,
                    activeVideoUrl: data.primaryVideoURL,
                    activeQualityLabel: data.quality ?? data.videoBackup?.first?.label ?? "原画"
                )
            } catch {
                parseState = .error(error.localizedDescription)
            }
        }
    }

    func selectQuality(url: String, qualityLabel: String) {
        if case let .success(response, _, _) = parseState {
            parseState = .success(response: response,
                                  activeVideoUrl: url,
                                  activeQualityLabel: qualityLabel)
        }
    }

    // MARK: - 历史操作

    func toggleFavorite(id: Int64, currentFavorite: Bool) {
        repository.toggleFavorite(id: id, current: currentFavorite)
    }

    func deleteHistory(id: Int64) {
        repository.deleteHistory(id: id)
    }

    func clearAllHistory() {
        repository.clearAllHistory()
    }

    func reparseFromHistory(_ item: ParseHistoryItem) {
        inputText = item.targetUrl
        parse(urlOverride: item.targetUrl)
    }

    func fillSampleUrl(_ url: String) {
        inputText = url
        parse(urlOverride: url)
    }

    // MARK: - API Key

    func saveCustomApiKey(_ key: String) {
        repository.setCustomApiKey(key)
        customApiKey = repository.getCustomApiKeyForDisplay()
        hasCustomApiKey = repository.hasCustomApiKey()
    }

    func resetToBuiltInKey() {
        repository.resetApiKey()
        customApiKey = repository.getCustomApiKeyForDisplay()
        hasCustomApiKey = repository.hasCustomApiKey()
    }

    // MARK: - 开关

    func toggleAutoParseClipboard(_ enabled: Bool) {
        settings.isAutoParseClipboard = enabled
        autoParseClipboard = enabled
    }

    // MARK: - 免责声明

    func acceptDisclaimer() {
        settings.isDisclaimerAccepted = true
        isDisclaimerAccepted = true
        showDisclaimerDialog = false
        declinedDisclaimer = false
    }

    func openDisclaimerModal() { showDisclaimerDialog = true }

    func dismissDisclaimerModal() {
        if isDisclaimerAccepted { showDisclaimerDialog = false }
    }

    func declineDisclaimer() {
        declinedDisclaimer = true
        showDisclaimerDialog = false
    }

    func reopenDisclaimer() {
        declinedDisclaimer = false
        showDisclaimerDialog = true
    }

    // MARK: - 接口连通性

    func testApiConnection() {
        apiStatusState = .checking
        Task {
            do {
                let result = try await repository.checkApiStatus()
                apiStatusState = .success(
                    latencyMs: result.latencyMs,
                    message: "接口连接正常，响应延迟 \(result.latencyMs)ms"
                )
            } catch {
                apiStatusState = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - 版本更新

    func checkAppUpdate(manual: Bool = false) {
        if manual { updateUiState = .checking }
        Task {
            do {
                let info = try await repository.checkAppUpdate()
                if isNewerVersion(info.version, info.versionCode) {
                    currentUpdateInfo = info
                    updateUiState = .available(info)
                    showUpdateDialog = true
                } else if manual {
                    updateUiState = .upToDate("当前已是最新版本 (v\(info.version ?? "1.0.0"))")
                } else {
                    updateUiState = .idle
                }
            } catch {
                if manual {
                    updateUiState = .error("检查更新失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func isNewerVersion(_ serverVersion: String?, _ serverCode: Int?) -> Bool {
        let currentCode = SettingsStore.appVersionCode
        let currentVersion = SettingsStore.appVersion

        if (serverCode ?? 1) > currentCode { return true }
        guard let serverVersion = serverVersion, !serverVersion.isEmpty else { return false }

        let serverParts = serverVersion.split(separator: ".").compactMap { Int($0) }
        let currentParts = currentVersion.split(separator: ".").compactMap { Int($0) }
        let maxLen = max(serverParts.count, currentParts.count)

        for index in 0..<maxLen {
            let s = index < serverParts.count ? serverParts[index] : 0
            let c = index < currentParts.count ? currentParts[index] : 0
            if s > c { return true }
            if s < c { return false }
        }
        return false
    }

    func dismissUpdateDialog() { showUpdateDialog = false }

    // MARK: - 保存目录

    func updateSaveDir(url: URL) {
        settings.setCustomSaveDir(url: url)
        customSaveDirURL = settings.resolveCustomSaveDir()
        customSaveDirName = settings.customSaveDirName
    }

    func resetSaveDir() {
        settings.resetCustomSaveDir()
        customSaveDirURL = nil
        customSaveDirName = settings.customSaveDirName
    }

    // MARK: - Toast

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            if self?.toastMessage == message { self?.toastMessage = nil }
        }
    }
}
