import Foundation

// MARK: - 设置存储 (对应 Android SharedPreferences "videoparse_prefs")

final class SettingsStore {

    static let shared = SettingsStore()

    // 内置 API Key —— 永久保护，不在 UI 明文展示
    static let builtInKey = "bp_live_6413cc32237e3611ec7bf0f14b76e463d07a5ad05d0ef2f9c526d3aaddd85eef"

    static let sponsorURL = "https://zs.69yr.cn"
    static let updateCheckURL = "https://raw.githubusercontent.com/yr123466/JSON/refs/heads/main/bugpkmini.json"
    static let feedbackEmail = "3176210846@qq.com"

    static let appVersion = "1.0.0"
    static let appVersionCode = 1

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let customApiKey = "custom_api_key"
        static let autoParseClipboard = "auto_parse_clipboard"
        static let preferHighQuality = "prefer_high_quality"
        static let disclaimerAccepted = "disclaimer_accepted"
        static let customSaveDirBookmark = "custom_save_dir_bookmark"
        static let customSaveDirName = "custom_save_dir_name"
    }

    // MARK: - API Key

    /// 用户自定义 Key（为空表示未配置）
    var customApiKey: String? {
        get {
            let value = defaults.string(forKey: Keys.customApiKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (value?.isEmpty ?? true) ? nil : value
        }
        set {
            let trimmed = newValue?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trimmed = trimmed, !trimmed.isEmpty {
                defaults.set(trimmed, forKey: Keys.customApiKey)
            } else {
                defaults.removeObject(forKey: Keys.customApiKey)
            }
        }
    }

    var hasCustomApiKey: Bool { customApiKey != nil }

    /// 实际用于请求的 Key：优先自定义，否则内置
    func activeApiKey() -> String { customApiKey ?? Self.builtInKey }

    func resetApiKey() { defaults.removeObject(forKey: Keys.customApiKey) }

    // MARK: - 偏好开关

    var isDisclaimerAccepted: Bool {
        get { defaults.bool(forKey: Keys.disclaimerAccepted) }
        set { defaults.set(newValue, forKey: Keys.disclaimerAccepted) }
    }

    var isAutoParseClipboard: Bool {
        get { defaults.object(forKey: Keys.autoParseClipboard) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.autoParseClipboard) }
    }

    var isPreferHighQuality: Bool {
        get { defaults.object(forKey: Keys.preferHighQuality) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.preferHighQuality) }
    }

    // MARK: - 自定义保存目录（安全作用域书签，等价 Android SAF 目录授权）

    var customSaveDirBookmark: Data? { defaults.data(forKey: Keys.customSaveDirBookmark) }

    var customSaveDirName: String {
        let name = defaults.string(forKey: Keys.customSaveDirName)
        return (name?.isEmpty ?? true) ? "系统默认下载目录 (文件App)" : (name ?? "")
    }

    func setCustomSaveDir(url: URL) {
        do {
            let data = try url.bookmarkData(options: .minimalBookmark,
                                            includingResourceValuesForKeys: nil,
                                            relativeTo: nil)
            defaults.set(data, forKey: Keys.customSaveDirBookmark)
            let name = url.lastPathComponent
            defaults.set(name.isEmpty ? "自定义文件夹" : name, forKey: Keys.customSaveDirName)
        } catch {
            defaults.set(url.absoluteString, forKey: Keys.customSaveDirName)
        }
    }

    func resolveCustomSaveDir() -> URL? {
        guard let data = customSaveDirBookmark else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: data,
                        options: [],
                        relativeTo: nil,
                        bookmarkDataIsStale: &stale)
    }

    func resetCustomSaveDir() {
        defaults.removeObject(forKey: Keys.customSaveDirBookmark)
        defaults.removeObject(forKey: Keys.customSaveDirName)
    }
}
