import Foundation

// MARK: - 平台信息 (对应 Android PlatformInfo / SupportedPlatforms)

struct PlatformInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let enName: String
    let iconEmoji: String
    let colorHex: UInt32
    let sampleUrl: String
    let formats: [String]
    let tips: String
    let isForeign: Bool
    let isTencent: Bool

    init(id: String,
         name: String,
         enName: String,
         iconEmoji: String,
         colorHex: UInt32,
         sampleUrl: String,
         formats: [String],
         tips: String,
         isForeign: Bool = false,
         isTencent: Bool = false) {
        self.id = id
        self.name = name
        self.enName = enName
        self.iconEmoji = iconEmoji
        self.colorHex = colorHex
        self.sampleUrl = sampleUrl
        self.formats = formats
        self.tips = tips
        self.isForeign = isForeign
        self.isTencent = isTencent
    }
}

enum SupportedPlatforms {

    // 完整平台列表 (与 Android allList 一致)
    static let allList: [PlatformInfo] = [
        PlatformInfo(
            id: "douyin",
            name: "抖音",
            enName: "Douyin",
            iconEmoji: "🎵",
            colorHex: 0xFF000000,
            sampleUrl: "0.00 复制打开抖音，看看【D2024yr的图文作品】这是一条测试贴，如此你看到了说明成功了  https://v.douyin.com/UlLYRaUfLOY/ Pkp:/ 08/05 :0pm c@N.jc ",
            formats: ["视频", "图集", "背景音乐", "高清原画"],
            tips: "打开抖音 App -> 点击分享 -> 复制链接，支持图集与视频"
        ),
        PlatformInfo(
            id: "kuaishou",
            name: "快手",
            enName: "Kuaishou",
            iconEmoji: "⚡",
            colorHex: 0xFFFF5722,
            sampleUrl: "https://v.kuaishou.com/xxxx",
            formats: ["短视频", "原声音乐", "封面"],
            tips: "快手短视频及快手极速版分享口令链接"
        ),
        PlatformInfo(
            id: "bilibili",
            name: "哔哩哔哩",
            enName: "Bilibili",
            iconEmoji: "📺",
            colorHex: 0xFF00AEEC,
            sampleUrl: "【Impactor 自签全流程教学 ios自签教学已测ios26.1可用其他版本需自测-哔哩哔哩】 https://b23.tv/Hsrdls0",
            formats: ["1080P/480P", "多音轨", "AV1/H264", "分P封面"],
            tips: "B站支持BV/av号或b23.tv短链，提供多分辨率下载"
        ),
        PlatformInfo(
            id: "xiaohongshu",
            name: "小红书",
            enName: "Xiaohongshu",
            iconEmoji: "📕",
            colorHex: 0xFFFF2442,
            sampleUrl: "http://xhslink.com/xxxx",
            formats: ["无水印图集", "视频笔记", "Live图"],
            tips: "支持小红书高清无水印图文多图打包及视频下载"
        ),
        PlatformInfo(
            id: "xigua",
            name: "西瓜视频",
            enName: "Xigua",
            iconEmoji: "🍉",
            colorHex: 0xFFFF3D00,
            sampleUrl: "https://v.ixigua.com/xxxx",
            formats: ["中长视频", "高清原画", "封面"],
            tips: "西瓜视频平台横版与竖版视频"
        ),
        PlatformInfo(
            id: "doubao",
            name: "豆包 AI",
            enName: "Doubao",
            iconEmoji: "🤖",
            colorHex: 0xFF3B82F6,
            sampleUrl: "https://www.doubao.com/thread/xb2J8bOUM4ePcAJph",
            formats: ["AI生成视频", "生成图片"],
            tips: "豆包 AI 生成的内容无水印提取"
        ),
        PlatformInfo(
            id: "jimeng",
            name: "即梦 AI",
            enName: "Jimeng",
            iconEmoji: "✨",
            colorHex: 0xFF8B5CF6,
            sampleUrl: "https://jimeng.jianying.com/xxxx",
            formats: ["AI视频", "超清原图"],
            tips: "即梦 AI 视频与生图平台无水印解析"
        ),
        PlatformInfo(
            id: "pipixia",
            name: "皮皮虾",
            enName: "Pipixia",
            iconEmoji: "🦐",
            colorHex: 0xFFFF6F00,
            sampleUrl: "https://h5.pipix.com/xxxx",
            formats: ["搞笑视频", "内涵神评封面"],
            tips: "皮皮虾搞笑社区视频去水印"
        ),
        PlatformInfo(
            id: "zhihu",
            name: "知乎",
            enName: "Zhihu",
            iconEmoji: "💡",
            colorHex: 0xFF0066FF,
            sampleUrl: "https://www.zhihu.com/zvideo/xxxx",
            formats: ["视频回答", "想法视频"],
            tips: "知乎视频回答与想法视频解析"
        ),
        PlatformInfo(
            id: "haokan",
            name: "好看视频",
            enName: "Haokan",
            iconEmoji: "👀",
            colorHex: 0xFFFF1744,
            sampleUrl: "https://haokan.baidu.com/v?vid=xxxx",
            formats: ["百度好看", "1080P高清"],
            tips: "百度好看视频平台无水印直链"
        ),
        PlatformInfo(
            id: "acfun",
            name: "AcFun (A站)",
            enName: "AcFun",
            iconEmoji: "🍌",
            colorHex: 0xFFFD4C5D,
            sampleUrl: "https://m.acfun.cn/v/?ac=xxxx",
            formats: ["番剧短片", "原画视频"],
            tips: "A站移动端短链与长链解析"
        ),
        PlatformInfo(
            id: "zuiyou",
            name: "最右",
            enName: "Zuiyou",
            iconEmoji: "😆",
            colorHex: 0xFF2196F3,
            sampleUrl: "https://share.izuiyou.com/xxxx",
            formats: ["神评视频", "段子视频"],
            tips: "最右贴子分享视频"
        ),
        PlatformInfo(
            id: "pearvideo",
            name: "梨视频",
            enName: "Pear Video",
            iconEmoji: "🍐",
            colorHex: 0xFF4CAF50,
            sampleUrl: "https://www.pearvideo.com/video_xxxx",
            formats: ["资讯短视频", "原画质"],
            tips: "梨视频一手现场资讯解析"
        ),
        // 目录 UI 隐藏：海外平台
        PlatformInfo(
            id: "tiktok",
            name: "TikTok",
            enName: "TikTok",
            iconEmoji: "🌐",
            colorHex: 0xFF25F4EE,
            sampleUrl: "https://vt.tiktok.com/xxxx",
            formats: ["海外无水印", "HD画质"],
            tips: "全球国际版短视频",
            isForeign: true
        ),
        PlatformInfo(
            id: "youtube",
            name: "油管 (YouTube)",
            enName: "YouTube",
            iconEmoji: "▶️",
            colorHex: 0xFFFF0000,
            sampleUrl: "https://youtube.com/shorts/xxxx",
            formats: ["Shorts短视频", "音频"],
            tips: "YouTube 视频",
            isForeign: true
        ),
        PlatformInfo(
            id: "instagram",
            name: "Instagram",
            enName: "Instagram",
            iconEmoji: "📸",
            colorHex: 0xFFE1306C,
            sampleUrl: "https://www.instagram.com/reel/xxxx",
            formats: ["Reels", "Posts图集"],
            tips: "Instagram",
            isForeign: true
        ),
        PlatformInfo(
            id: "twitter",
            name: "X (Twitter)",
            enName: "X / Twitter",
            iconEmoji: "🐦",
            colorHex: 0xFF1D9BF0,
            sampleUrl: "https://x.com/xxxx/status/xxxx",
            formats: ["推文视频", "动图"],
            tips: "X 推特",
            isForeign: true
        ),
        // 目录 UI 隐藏：腾讯系平台
        PlatformInfo(
            id: "wx_channels",
            name: "微信视频号",
            enName: "Channels",
            iconEmoji: "💬",
            colorHex: 0xFF07C160,
            sampleUrl: "https://weixin.qq.com/xxxx",
            formats: ["视频原画", "封面提取"],
            tips: "微信视频号分享文本解析",
            isTencent: true
        ),
        PlatformInfo(
            id: "weishi",
            name: "微视",
            enName: "Weishi",
            iconEmoji: "🎬",
            colorHex: 0xFFFF0055,
            sampleUrl: "https://isee.weishi.qq.com/xxxx",
            formats: ["腾讯微视", "背景音乐"],
            tips: "腾讯微视短视频",
            isTencent: true
        )
    ]

    // “支持平台”页展示列表：仅合规的国内非腾讯系平台
    static let displayList: [PlatformInfo] = allList.filter { !$0.isForeign && !$0.isTencent }
}
