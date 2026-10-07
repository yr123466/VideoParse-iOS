import Foundation

// MARK: - 解析响应 (对应 Android ParseResponse / ParseData 及子模型)

struct ParseResponse: Codable {
    let code: Int?
    let msg: String?
    let message: String?
    let error: String?
    let platform: String?
    let data: ParseData?
    let requestId: String?

    /// 统一提取错误文案（对应 Kotlin: msg ?: message ?: error ?: 默认值）
    var errorMessage: String {
        return msg ?? message ?? error ?? "解析失败，请检查链接或接口状态"
    }

    enum CodingKeys: String, CodingKey {
        case code, msg, message, error, platform, data, requestId
    }
}

struct ParseData: Codable {
    let type: String?
    let title: String?
    let desc: String?
    let cover: String?
    let url: String?
    let quality: String?
    let duration: Double?
    let size: Int64?
    let sizeLabel: String?
    let publishTime: String?
    let author: AuthorInfo?
    let music: MusicInfo?
    let urls: [String]?
    let images: [String]?
    let videoBackup: [VideoBackupItem]?
    let audioBackup: [AudioBackupItem]?
    let livePhoto: [LivePhotoItem]?
    let extra: ExtraInfo?
    let label: String?
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case type, title, desc, cover, url, quality, duration, size
        case sizeLabel = "size_label"
        case publishTime = "publish_time"
        case author, music, urls, images
        case videoBackup = "video_backup"
        case audioBackup = "audio_backup"
        case livePhoto = "live_photo"
        case extra, label, width, height
    }

    /// Live Photo 中首帧对应的视频直链
    var liveVideoURL: String? {
        return livePhoto?.first?.video
    }

    /// 全部图片（images + urls + livePhoto.image），去重
    var allImages: [String] {
        var result: [String] = []
        result.append(contentsOf: images ?? [])
        result.append(contentsOf: urls ?? [])
        result.append(contentsOf: (livePhoto ?? []).compactMap { $0.image })
        var seen = Set<String>()
        return result.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    /// 首选视频直链
    var primaryVideoURL: String {
        return url ?? liveVideoURL ?? videoBackup?.first?.url ?? ""
    }

    /// 是否为纯图集帖（有图且无视频）
    var isImagePost: Bool {
        return !allImages.isEmpty && primaryVideoURL.isEmpty
    }
}

struct AuthorInfo: Codable {
    let name: String?
    let id: String?
    let avatar: String?
}

struct MusicInfo: Codable {
    let title: String?
    let author: String?
    let url: String?
    let cover: String?
}

struct VideoBackupItem: Codable {
    let label: String?
    let quality: String?
    let url: String?
    let sizeLabel: String?
    let size: Int64?
    let format: String?
    let codec: String?
    let bitRate: Int64?
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case label, quality, url
        case sizeLabel = "size_label"
        case size, format, codec
        case bitRate = "bit_rate"
        case width, height
    }

    /// 展示用清晰度标签
    var displayLabel: String {
        return label ?? quality ?? "未知清晰度"
    }
}

struct AudioBackupItem: Codable {
    let label: String?
    let quality: String?
    let url: String?
    let format: String?
    let codec: String?
    let bitRate: Int64?

    enum CodingKeys: String, CodingKey {
        case label, quality, url, format, codec
        case bitRate = "bit_rate"
    }
}

struct ExtraInfo: Codable {
    let statistics: StatisticsInfo?
    let shareUrl: String?

    enum CodingKeys: String, CodingKey {
        case statistics
        case shareUrl = "share_url"
    }
}

struct StatisticsInfo: Codable {
    let diggCount: Int64?
    let likeCount: Int64?
    let commentCount: Int64?
    let collectCount: Int64?
    let shareCount: Int64?
    let playCount: Int64?

    enum CodingKeys: String, CodingKey {
        case diggCount = "digg_count"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case collectCount = "collect_count"
        case shareCount = "share_count"
        case playCount = "play_count"
    }
}

struct LivePhotoItem: Codable {
    let image: String?
    let video: String?
}
