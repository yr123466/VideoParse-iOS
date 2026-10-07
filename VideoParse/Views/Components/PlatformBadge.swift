import SwiftUI

/// 平台标签徽章（对应 Android PlatformBadge）
struct PlatformBadge: View {
    let platform: String

    private var info: (label: String, emoji: String, color: Color) {
        switch platform.lowercased() {
        case "douyin":      return ("抖音", "🎵", Color(hex: 0xFF1E293B))
        case "kuaishou":    return ("快手", "⚡", Color(hex: 0xFFFF5722))
        case "bilibili":    return ("哔哩哔哩", "📺", Color(hex: 0xFF00AEEC))
        case "xiaohongshu": return ("小红书", "📕", Color(hex: 0xFFFF2442))
        case "tiktok":      return ("TikTok", "🌐", Color(hex: 0xFF00796B))
        case "youtube":     return ("YouTube", "▶️", Color(hex: 0xFFCC0000))
        case "weibo":       return ("微博", "👁️", Color(hex: 0xFFE6162D))
        case "xigua":       return ("西瓜视频", "🍉", Color(hex: 0xFFE65100))
        case "wx_channels": return ("视频号", "💬", Color(hex: 0xFF07C160))
        case "doubao":      return ("豆包", "🤖", Color(hex: 0xFF2563EB))
        case "jimeng":      return ("即梦", "✨", Color(hex: 0xFF7C3AED))
        case "pipixia":     return ("皮皮虾", "🦐", Color(hex: 0xFFD97706))
        case "instagram":   return ("Instagram", "📸", Color(hex: 0xFFC13584))
        case "twitter":     return ("X/Twitter", "🐦", Color(hex: 0xFF0284C7))
        case "zhihu":       return ("知乎", "💡", Color(hex: 0xFF0066FF))
        case "acfun":       return ("AcFun", "🍌", Color(hex: 0xFFEA580C))
        default:            return (platform.isEmpty ? "全网" : platform, "🔗", AppTheme.primary)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(info.emoji)
                .font(.system(size: 11))
            Text(info.label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(info.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(info.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
