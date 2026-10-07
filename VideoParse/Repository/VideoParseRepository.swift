import Foundation

// MARK: - 业务仓库 (对应 Android VideoParseRepository)

final class VideoParseRepository {

    static let shared = VideoParseRepository()

    private let api = APIClient.shared
    private let settings = SettingsStore.shared
    let history = HistoryStore.shared

    // URL 提取正则（与 Android 端保持一致）
    private let urlPattern = "https?://[a-zA-Z0-9_.-]+(?:\\.[a-zA-Z]{2,})+(?:/[^\\s\\u4e00-\\u9fa5]*)?"

    private init() {}

    // MARK: - 常量透出

    var sponsorURL: String { SettingsStore.sponsorURL }
    var feedbackEmail: String { SettingsStore.feedbackEmail }

    // MARK: - API Key

    func getApiKey() -> String { settings.activeApiKey() }
    func hasCustomApiKey() -> Bool { settings.hasCustomApiKey }
    func getCustomApiKeyForDisplay() -> String { settings.customApiKey ?? "" }
    func setCustomApiKey(_ key: String) { settings.customApiKey = key }
    func resetApiKey() { settings.resetApiKey() }

    // MARK: - URL 解析

    /// 从分享文本中提取首个 http(s) 链接
    func extractUrl(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: urlPattern) else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let matchRange = Range(match.range, in: text) {
            return String(text[matchRange])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 依据链接识别平台
    func detectPlatform(_ url: String) -> String {
        let lower = url.lowercased()
        if lower.contains("douyin") || lower.contains("iesdouyin") { return "douyin" }
        if lower.contains("kuaishou") || lower.contains("kwai") { return "kuaishou" }
        if lower.contains("bilibili") || lower.contains("b23.tv") { return "bilibili" }
        if lower.contains("xiaohongshu") || lower.contains("xhslink") { return "xiaohongshu" }
        if lower.contains("weixin") || lower.contains("wechat") || lower.contains("finder") { return "wx_channels" }
        if lower.contains("weishi") { return "weishi" }
        if lower.contains("tiktok") { return "tiktok" }
        if lower.contains("youtube") || lower.contains("youtu.be") { return "youtube" }
        if lower.contains("weibo") { return "weibo" }
        if lower.contains("ixigua") { return "xigua" }
        if lower.contains("pipix") { return "pipixia" }
        if lower.contains("zhihu") { return "zhihu" }
        return "other"
    }

    // MARK: - 解析视频

    func parseVideo(input: String) async throws -> ParseResponse {
        let extracted = extractUrl(input)
        guard !extracted.isEmpty, extracted.lowercased().hasPrefix("http") else {
            throw NSError(domain: "VideoParse", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "请输入有效的网络链接地址 (http/https)"])
        }

        let key = getApiKey()
        let response = try await api.parseVideo(url: extracted, key: key)

        guard response.code == 200, let data = response.data else {
            throw NSError(domain: "VideoParse", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: response.errorMessage])
        }

        let effectiveVideoUrl = data.url ?? data.liveVideoURL ?? ""
        let allImages = data.allImages
        let isImagePost = !allImages.isEmpty && effectiveVideoUrl.isEmpty

        let item = ParseHistoryItem(
            originalInput: input,
            targetUrl: extracted,
            title: data.title ?? data.desc ?? "未命名作品",
            desc: data.desc ?? "",
            coverUrl: data.cover ?? (allImages.first ?? ""),
            videoUrl: effectiveVideoUrl,
            audioUrl: data.music?.url ?? "",
            authorName: data.author?.name ?? "佚名",
            authorAvatar: data.author?.avatar ?? "",
            platform: response.platform ?? detectPlatform(extracted),
            mediaType: isImagePost ? "image" : (data.type == "live" ? "live" : "video"),
            duration: data.duration ?? 0.0,
            sizeLabel: data.sizeLabel ?? "",
            quality: data.quality ?? data.label ?? "原画",
            imagesJson: allImages.joined(separator: ","),
            isFavorite: false,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )

        await MainActor.run {
            self.history.insert(item)
        }

        return response
    }

    // MARK: - 接口连通性测试

    func checkApiStatus() async throws -> (latencyMs: Int, message: String) {
        let start = Date()
        let data = try await api.checkApiStatus()
        let latency = Int(Date().timeIntervalSince(start) * 1000)
        let content = String(data: data, encoding: .utf8) ?? ""
        return (latency, content)
    }

    // MARK: - 检查更新

    func checkAppUpdate() async throws -> AppUpdateInfo {
        return try await api.checkUpdate()
    }

    // MARK: - 历史操作

    func toggleFavorite(id: Int64, current: Bool) {
        history.toggleFavorite(id: id, current: current)
    }

    func deleteHistory(id: Int64) {
        history.delete(id: id)
    }

    func clearAllHistory() {
        history.clearAll()
    }
}
