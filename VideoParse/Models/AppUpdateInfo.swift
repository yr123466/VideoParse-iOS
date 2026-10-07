import Foundation

// MARK: - 应用更新信息 (对应 Android AppUpdateInfo)

struct AppUpdateInfo: Codable {
    var version: String? = "1.0.0"
    var versionCode: Int? = 1
    var forceUpdate: Bool? = false
    var updateTitle: String? = "发现新版本"
    var updateContent: String?
    var downloadUrl: String?
    var updateTime: String?
    var updateSize: String?

    enum CodingKeys: String, CodingKey {
        case version, versionCode, forceUpdate, updateTitle, updateContent
        case downloadUrl, updateTime, updateSize
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decodeIfPresent(String.self, forKey: .version)) ?? "1.0.0"
        versionCode = (try? c.decodeIfPresent(Int.self, forKey: .versionCode)) ?? 1
        forceUpdate = (try? c.decodeIfPresent(Bool.self, forKey: .forceUpdate)) ?? false
        updateTitle = (try? c.decodeIfPresent(String.self, forKey: .updateTitle)) ?? "发现新版本"
        updateContent = try? c.decodeIfPresent(String.self, forKey: .updateContent)
        downloadUrl = try? c.decodeIfPresent(String.self, forKey: .downloadUrl)
        updateTime = try? c.decodeIfPresent(String.self, forKey: .updateTime)
        updateSize = try? c.decodeIfPresent(String.self, forKey: .updateSize)
    }

    init() {}
}
