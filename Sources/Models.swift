import Foundation
import SwiftUI

// MARK: - 宽松 JSON 取值工具
// 第三方接口字段类型不稳定（数字/字符串混用、null、缺字段），统一用字典解析避免解码整体失败。

extension Dictionary where Key == String, Value == Any {

    private func safeValue(_ key: String) -> Any? {
        guard let v = self[key] else { return nil }
        if v is NSNull { return nil }
        return v
    }

    func str(_ key: String) -> String? {
        guard let v = safeValue(key) else { return nil }
        if let s = v as? String {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        if let n = v as? NSNumber { return n.stringValue }
        return nil
    }

    func dbl(_ key: String) -> Double? {
        guard let v = safeValue(key) else { return nil }
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String { return Double(s) }
        return nil
    }

    func intv(_ key: String) -> Int? {
        guard let v = safeValue(key) else { return nil }
        if let n = v as? NSNumber { return n.intValue }
        if let s = v as? String { return Int(s) }
        return nil
    }

    func i64(_ key: String) -> Int64? {
        guard let v = safeValue(key) else { return nil }
        if let n = v as? NSNumber { return n.int64Value }
        if let s = v as? String { return Int64(s) }
        return nil
    }

    func dict(_ key: String) -> [String: Any]? {
        safeValue(key) as? [String: Any]
    }

    func bool(_ key: String) -> Bool? {
        guard let v = safeValue(key) else { return nil }
        if let b = v as? Bool { return b }
        if let n = v as? NSNumber { return n.boolValue }
        if let s = v as? String { return ["true", "1", "yes"].contains(s.lowercased()) }
        return nil
    }

    func dictArray(_ key: String) -> [[String: Any]] {
        (safeValue(key) as? [Any])?.compactMap { $0 as? [String: Any] } ?? []
    }

    func stringArray(_ key: String) -> [String] {
        guard let raw = safeValue(key) as? [Any] else { return [] }
        var out: [String] = []
        for element in raw {
            if let s = element as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { out.append(t) }
            } else if let d = element as? [String: Any], let s = d.str("url") {
                out.append(s)
            }
        }
        return out
    }
}

// MARK: - 解析结果模型

struct AuthorInfo {
    var name: String?
    var id: String?
    var avatar: String?

    init(json: [String: Any]) {
        name = json.str("name")
        id = json.str("id")
        avatar = json.str("avatar")
    }
}

struct MusicInfo {
    var title: String? = nil
    var author: String? = nil
    var url: String? = nil
    var cover: String? = nil
}

struct VideoBackupItem {
    var label: String?
    var quality: String?
    var url: String?
    var sizeLabel: String?
    var size: Int64?
    var format: String?
    var codec: String?
    var bitRate: Int64?
    var width: Int?
    var height: Int?

    init(json: [String: Any]) {
        label = json.str("label")
        quality = json.str("quality")
        url = json.str("url")
        sizeLabel = json.str("size_label")
        size = json.i64("size")
        format = json.str("format")
        codec = json.str("codec")
        bitRate = json.i64("bit_rate")
        width = json.intv("width")
        height = json.intv("height")
    }

    var title: String {
        if let label = label { return label }
        if let q = quality { return q.uppercased() }
        return "默认清晰度"
    }
}

struct AudioBackupItem {
    var label: String?
    var quality: String?
    var url: String?
    var format: String?

    init(json: [String: Any]) {
        label = json.str("label")
        quality = json.str("quality")
        url = json.str("url")
        format = json.str("format")
    }
}

struct LivePhotoItem {
    var image: String?
    var video: String?

    init(json: [String: Any]) {
        image = json.str("image")
        video = json.str("video")
    }
}

struct StatisticsInfo {
    var diggCount: Int64?
    var likeCount: Int64?
    var commentCount: Int64?
    var collectCount: Int64?
    var shareCount: Int64?
    var playCount: Int64?

    init(json: [String: Any]) {
        diggCount = json.i64("digg_count")
        likeCount = json.i64("like_count")
        commentCount = json.i64("comment_count")
        collectCount = json.i64("collect_count")
        shareCount = json.i64("share_count")
        playCount = json.i64("play_count")
    }

    var likeTotal: Int64? { likeCount ?? diggCount }
}

struct ParseData {
    var type: String = "video"
    var title: String?
    var desc: String?
    var cover: String?
    var url: String?
    var quality: String?
    var duration: Double?
    var size: Int64?
    var sizeLabel: String?
    var publishTime: String?
    var author: AuthorInfo?
    var music: MusicInfo?
    var urls: [String] = []
    var images: [String] = []
    var pics: [String] = []
    var photos: [String] = []
    var imageList: [String] = []
    var imgList: [String] = []
    var videoBackup: [VideoBackupItem] = []
    var audioBackup: [AudioBackupItem] = []
    var livePhoto: [LivePhotoItem] = []
    var label: String?
    var width: Int?
    var height: Int?
    var statistics: StatisticsInfo?
    var createTime: Int64?

    init(json: [String: Any]) {
        type = json.str("type") ?? "video"
        title = json.str("title")
        desc = json.str("desc")
        cover = json.str("cover")
        url = json.str("url")
        quality = json.str("quality")
        duration = json.dbl("duration")
        size = json.i64("size")
        sizeLabel = json.str("size_label")
        publishTime = json.str("publish_time")
        if let a = json.dict("author") { author = AuthorInfo(json: a) }
        if let m = json.dict("music") {
            var info = MusicInfo()
            info.title = m.str("title")
            info.author = m.str("author")
            info.url = m.str("url")
            info.cover = m.str("cover")
            music = info
        }
        urls = json.stringArray("urls")
        images = json.stringArray("images")
        pics = json.stringArray("pics")
        photos = json.stringArray("photos")
        imageList = json.stringArray("image_list")
        imgList = json.stringArray("img_list")
        videoBackup = json.dictArray("video_backup").map { VideoBackupItem(json: $0) }
        audioBackup = json.dictArray("audio_backup").map { AudioBackupItem(json: $0) }
        livePhoto = json.dictArray("live_photo").map { LivePhotoItem(json: $0) }
        label = json.str("label")
        width = json.intv("width")
        height = json.intv("height")
        createTime = json.i64("create_time")
        if let extra = json.dict("extra"), let stat = extra.dict("statistics") {
            statistics = StatisticsInfo(json: stat)
        }
    }

    /// 全部可用于展示/下载的图片，去重
    func extractAllImages() -> [String] {
        var list = images + urls + pics + photos + imageList + imgList
        list += livePhoto.compactMap { $0.image }
        let cleaned = list
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.lowercased().hasPrefix("http") }
        var seen = Set<String>()
        let unique = cleaned.filter { seen.insert($0).inserted }
        if unique.isEmpty, let c = cover, c.lowercased().hasPrefix("http"), (url ?? "").isEmpty {
            return [c]
        }
        return unique
    }

    func extractAudioUrl() -> String? {
        if let u = music?.url, !u.isEmpty { return u }
        if let u = audioBackup.first?.url, !u.isEmpty { return u }
        return nil
    }

    func getEffectiveMusic() -> MusicInfo? {
        if let m = music, let u = m.url, !u.isEmpty { return m }
        if let backup = audioBackup.first?.url, !backup.isEmpty {
            var info = MusicInfo()
            info.title = "\(title ?? "作品") (原声音频)"
            info.author = author?.name ?? "佚名"
            info.url = backup
            info.cover = cover
            return info
        }
        return nil
    }

    var liveVideoUrl: String? {
        livePhoto.compactMap { $0.video }.first
    }

    var primaryVideoUrl: String {
        url ?? liveVideoUrl ?? videoBackup.first?.url ?? ""
    }

    var primaryQuality: String {
        quality ?? videoBackup.first?.label ?? label ?? "原画"
    }

    var isImagePost: Bool {
        let imgs = extractAllImages()
        guard !imgs.isEmpty else { return false }
        return primaryVideoUrl.isEmpty || type == "image" || type == "live" || imgs.count > 1
    }
}

struct ParseResponse {
    var code: Int?
    var msg: String?
    var message: String?
    var error: String?
    var platform: String?
    var data: ParseData?

    init(json: [String: Any]) {
        code = json.intv("code")
        msg = json.str("msg")
        message = json.str("message")
        error = json.str("error")
        platform = json.str("platform")
        if let d = json.dict("data") { data = ParseData(json: d) }
    }

    var errorText: String {
        msg ?? message ?? error ?? "解析失败，请检查链接或接口状态"
    }
}

struct AppUpdateInfo {
    var version: String = "1.0.0"
    var versionCode: Int = 1
    var forceUpdate: Bool = false
    var updateTitle: String = "发现新版本"
    var updateContent: String = ""
    var downloadUrl: String = ""
    var updateTime: String = ""
    var updateSize: String = ""

    init(json: [String: Any]) {
        version = json.str("version") ?? "1.0.0"
        versionCode = json.intv("versionCode") ?? json.intv("version_code") ?? 1
        forceUpdate = json.bool("forceUpdate") ?? json.bool("force_update") ?? false
        updateTitle = json.str("updateTitle") ?? json.str("update_title") ?? "发现新版本"
        updateContent = json.str("updateContent") ?? json.str("update_content") ?? ""
        downloadUrl = json.str("downloadUrl") ?? json.str("download_url") ?? ""
        updateTime = json.str("updateTime") ?? json.str("update_time") ?? ""
        updateSize = json.str("updateSize") ?? json.str("update_size") ?? ""
    }
}

// MARK: - 平台信息

struct PlatformInfo: Identifiable {
    let id: String
    let name: String
    let enName: String
    let emoji: String
    let color: Color
    let sampleUrl: String
    let formats: [String]
    let tips: String
    var isForeign: Bool = false
    var isTencent: Bool = false
}

enum SupportedPlatforms {

    static let all: [PlatformInfo] = [
        PlatformInfo(id: "douyin", name: "抖音", enName: "Douyin", emoji: "🎵",
                     color: Color(hex: 0x111111),
                     sampleUrl: "0.00 复制打开抖音，看看【D2024yr的图文作品】这是一条测试贴，如此你看到了说明成功了  https://v.douyin.com/UlLYRaUfLOY/ Pkp:/ 08/05 :0pm c@N.jc ",
                     formats: ["视频", "图集", "背景音乐", "高清原画"],
                     tips: "打开抖音 App → 点击分享 → 复制链接，支持图集与视频"),
        PlatformInfo(id: "kuaishou", name: "快手", enName: "Kuaishou", emoji: "⚡",
                     color: Color(hex: 0xFF5722),
                     sampleUrl: "https://v.kuaishou.com/xxxx",
                     formats: ["短视频", "原声音乐", "封面"],
                     tips: "快手短视频及快手极速版分享口令链接"),
        PlatformInfo(id: "bilibili", name: "哔哩哔哩", enName: "Bilibili", emoji: "📺",
                     color: Color(hex: 0x00AEEC),
                     sampleUrl: "【Impactor 自签全流程教学 ios自签教学已测ios26.1可用其他版本需自测-哔哩哔哩】 https://b23.tv/Hsrdls0",
                     formats: ["1080P/480P", "多音轨", "AV1/H264", "分P封面"],
                     tips: "B站支持 BV/av 号或 b23.tv 短链，提供多分辨率下载"),
        PlatformInfo(id: "xiaohongshu", name: "小红书", enName: "Xiaohongshu", emoji: "📕",
                     color: Color(hex: 0xFF2442),
                     sampleUrl: "http://xhslink.com/xxxx",
                     formats: ["无水印图集", "视频笔记", "Live图"],
                     tips: "支持小红书高清无水印图文多图打包及视频下载"),
        PlatformInfo(id: "xigua", name: "西瓜视频", enName: "Xigua", emoji: "🍉",
                     color: Color(hex: 0xFF3D00),
                     sampleUrl: "https://v.ixigua.com/xxxx",
                     formats: ["中长视频", "高清原画", "封面"],
                     tips: "西瓜视频平台横版与竖版视频"),
        PlatformInfo(id: "doubao", name: "豆包 AI", enName: "Doubao", emoji: "🤖",
                     color: Color(hex: 0x3B82F6),
                     sampleUrl: "https://www.doubao.com/thread/xb2J8bOUM4ePcAJph",
                     formats: ["AI生成视频", "生成图片"],
                     tips: "豆包 AI 生成的内容无水印提取"),
        PlatformInfo(id: "jimeng", name: "即梦 AI", enName: "Jimeng", emoji: "✨",
                     color: Color(hex: 0x8B5CF6),
                     sampleUrl: "https://jimeng.jianying.com/xxxx",
                     formats: ["AI视频", "超清原图"],
                     tips: "即梦 AI 视频与生图平台无水印解析"),
        PlatformInfo(id: "pipixia", name: "皮皮虾", enName: "Pipixia", emoji: "🦐",
                     color: Color(hex: 0xFF6F00),
                     sampleUrl: "https://h5.pipix.com/xxxx",
                     formats: ["搞笑视频", "内涵神评封面"],
                     tips: "皮皮虾搞笑社区视频去水印"),
        PlatformInfo(id: "zhihu", name: "知乎", enName: "Zhihu", emoji: "💡",
                     color: Color(hex: 0x0066FF),
                     sampleUrl: "https://www.zhihu.com/zvideo/xxxx",
                     formats: ["视频回答", "想法视频"],
                     tips: "知乎视频回答与想法视频解析"),
        PlatformInfo(id: "haokan", name: "好看视频", enName: "Haokan", emoji: "👀",
                     color: Color(hex: 0xFF1744),
                     sampleUrl: "https://haokan.baidu.com/v?vid=xxxx",
                     formats: ["百度好看", "1080P高清"],
                     tips: "百度好看视频平台无水印直链"),
        PlatformInfo(id: "acfun", name: "AcFun (A站)", enName: "AcFun", emoji: "🍌",
                     color: Color(hex: 0xFD4C5D),
                     sampleUrl: "https://m.acfun.cn/v/?ac=xxxx",
                     formats: ["番剧短片", "原画视频"],
                     tips: "A站移动端短链与长链解析"),
        PlatformInfo(id: "zuiyou", name: "最右", enName: "Zuiyou", emoji: "😆",
                     color: Color(hex: 0x2196F3),
                     sampleUrl: "https://share.izuiyou.com/xxxx",
                     formats: ["神评视频", "段子视频"],
                     tips: "最右贴子分享视频"),
        PlatformInfo(id: "pearvideo", name: "梨视频", enName: "Pear Video", emoji: "🍐",
                     color: Color(hex: 0x4CAF50),
                     sampleUrl: "https://www.pearvideo.com/video_xxxx",
                     formats: ["资讯短视频", "原画质"],
                     tips: "梨视频一手现场资讯解析"),
        PlatformInfo(id: "tiktok", name: "TikTok", enName: "TikTok", emoji: "🌐",
                     color: Color(hex: 0x25F4EE),
                     sampleUrl: "https://vt.tiktok.com/xxxx",
                     formats: ["海外无水印", "HD画质"],
                     tips: "全球国际版短视频", isForeign: true),
        PlatformInfo(id: "youtube", name: "油管 (YouTube)", enName: "YouTube", emoji: "▶️",
                     color: Color(hex: 0xFF0000),
                     sampleUrl: "https://youtube.com/shorts/xxxx",
                     formats: ["Shorts短视频", "音频"],
                     tips: "YouTube 视频", isForeign: true),
        PlatformInfo(id: "instagram", name: "Instagram", enName: "Instagram", emoji: "📸",
                     color: Color(hex: 0xE1306C),
                     sampleUrl: "https://www.instagram.com/reel/xxxx",
                     formats: ["Reels", "Posts图集"],
                     tips: "Instagram", isForeign: true),
        PlatformInfo(id: "twitter", name: "X (Twitter)", enName: "X / Twitter", emoji: "🐦",
                     color: Color(hex: 0x1D9BF0),
                     sampleUrl: "https://x.com/xxxx/status/xxxx",
                     formats: ["推文视频", "动图"],
                     tips: "X 推特", isForeign: true),
        PlatformInfo(id: "wx_channels", name: "微信视频号", enName: "Channels", emoji: "💬",
                     color: Color(hex: 0x07C160),
                     sampleUrl: "https://weixin.qq.com/xxxx",
                     formats: ["视频原画", "封面提取"],
                     tips: "微信视频号分享文本解析", isTencent: true),
        PlatformInfo(id: "weishi", name: "微视", enName: "Weishi", emoji: "🎬",
                     color: Color(hex: 0xFF0055),
                     sampleUrl: "https://isee.weishi.qq.com/xxxx",
                     formats: ["腾讯微视", "背景音乐"],
                     tips: "腾讯微视短视频", isTencent: true)
    ]

    /// 平台页只展示合规的国内主流平台
    static let display: [PlatformInfo] = all.filter { !$0.isForeign && !$0.isTencent }

    static func info(_ id: String?) -> PlatformInfo? {
        guard let id = id else { return nil }
        return all.first { $0.id == id }
    }

    static func name(_ id: String?) -> String {
        info(id)?.name ?? "其他平台"
    }

    static func emoji(_ id: String?) -> String {
        info(id)?.emoji ?? "🔗"
    }

    static func color(_ id: String?) -> Color {
        info(id)?.color ?? Color(hex: 0x64748B)
    }

    /// 从链接识别平台
    static func detect(_ url: String) -> String {
        let lower = url.lowercased()
        let rules: [(String, [String])] = [
            ("douyin", ["douyin", "iesdouyin"]),
            ("kuaishou", ["kuaishou", "kwai"]),
            ("bilibili", ["bilibili", "b23.tv"]),
            ("xiaohongshu", ["xiaohongshu", "xhslink"]),
            ("wx_channels", ["weixin", "wechat", "finder"]),
            ("weishi", ["weishi"]),
            ("tiktok", ["tiktok"]),
            ("youtube", ["youtube", "youtu.be"]),
            ("xigua", ["ixigua"]),
            ("pipixia", ["pipix"]),
            ("zhihu", ["zhihu"]),
            ("doubao", ["doubao"]),
            ("jimeng", ["jimeng"]),
            ("acfun", ["acfun"]),
            ("zuiyou", ["izuiyou"]),
            ("pearvideo", ["pearvideo"]),
            ("haokan", ["haokan"]),
            ("instagram", ["instagram"]),
            ("twitter", ["twitter", "x.com"])
        ]
        for (id, keys) in rules where keys.contains(where: { lower.contains($0) }) {
            return id
        }
        return "other"
    }
}

// MARK: - 本地素材记录

struct HistoryItem: Codable, Identifiable {
    var id: UUID = UUID()
    var originalInput: String = ""
    var targetUrl: String = ""
    var title: String = ""
    var desc: String = ""
    var coverUrl: String = ""
    var videoUrl: String = ""
    var audioUrl: String = ""
    var authorName: String = ""
    var authorAvatar: String = ""
    var platform: String = "other"
    var mediaType: String = "video"
    var duration: Double = 0
    var sizeLabel: String = ""
    var quality: String = ""
    var images: [String] = []
    var isFavorite: Bool = false
    var timestamp: Date = Date()

    var imageList: [String] {
        if images.isEmpty {
            if !coverUrl.isEmpty && (mediaType == "image" || mediaType == "live") { return [coverUrl] }
            return []
        }
        return images.filter { $0.lowercased().hasPrefix("http") }
    }

    var isImageMedia: Bool {
        if mediaType == "audio" { return false }
        return mediaType == "image" || mediaType == "live" || !imageList.isEmpty
            || (videoUrl.isEmpty && !coverUrl.isEmpty)
    }

    var displayTitle: String { title.isEmpty ? "未命名作品" : title }
    var displayAuthor: String { authorName.isEmpty ? "佚名" : authorName }
    var platformName: String { SupportedPlatforms.name(platform) }

    var typeLabel: String {
        if mediaType == "audio" { return "MP3" }
        if isImageMedia { return "图集(\(imageList.count))" }
        return "视频"
    }
}

// MARK: - 格式化工具

enum Fmt {

    static func duration(_ seconds: Double?) -> String {
        guard let s = seconds, s > 0 else { return "" }
        let total = Int(s.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let sec = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }

    static func size(_ bytes: Int64?) -> String {
        guard let b = bytes, b > 0 else { return "" }
        let mb = Double(b) / 1024 / 1024
        if mb >= 1024 { return String(format: "%.2fGB", mb / 1024) }
        if mb >= 1 { return String(format: "%.2fMB", mb) }
        return String(format: "%.0fKB", max(mb * 1024, 1))
    }

    static func count(_ n: Int64?) -> String {
        guard let n = n else { return "0" }
        if n >= 10000 { return String(format: "%.1fw", Double(n) / 10000) }
        return "\(n)"
    }

    static func relative(_ date: Date) -> String {
        let interval = -date.timeIntervalSinceNow
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: date)
    }
}
