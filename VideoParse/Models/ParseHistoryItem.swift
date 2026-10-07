import Foundation

// MARK: - 解析历史记录 (对应 Android Room 实体 ParseHistoryEntity)

struct ParseHistoryItem: Identifiable, Codable, Equatable {
    var id: Int64 = 0
    var originalInput: String
    var targetUrl: String
    var title: String
    var desc: String
    var coverUrl: String
    var videoUrl: String
    var audioUrl: String
    var authorName: String
    var authorAvatar: String
    var platform: String
    var mediaType: String = "video"   // video / image / live
    var duration: Double = 0.0
    var sizeLabel: String = ""
    var quality: String = ""
    var imagesJson: String = ""
    var isFavorite: Bool = false
    var timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)

    /// 从逗号分隔字符串还原图片列表
    var images: [String] {
        return imagesJson
            .split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
}
