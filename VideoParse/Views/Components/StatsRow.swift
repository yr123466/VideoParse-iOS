import SwiftUI

/// 作者 / 平台头部信息（对应 Android MediaHeaderInfo）
struct MediaHeaderInfo: View {
    let title: String
    let author: AuthorInfo?
    let platform: String
    let publishTime: String?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let avatar = author?.avatar, !avatar.isEmpty {
                RemoteImage(urlString: avatar, contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            }

            HStack(spacing: 8) {
                PlatformBadge(platform: platform)
                Text(author?.name ?? "网络博主")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.onSurface)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if let publishTime = publishTime, !publishTime.isEmpty {
                Text(String(publishTime.prefix(10)))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 数据统计行（时长 / 体积 / 点赞 / 评论 / 分享 / 播放）
struct StatsRow: View {
    let statistics: StatisticsInfo?
    let duration: Double?
    let sizeLabel: String?

    private var chips: [(icon: String, text: String)] {
        var result: [(String, String)] = []

        if let duration = duration, duration > 0 {
            let total = Int(duration)
            result.append(("clock", String(format: "%02d:%02d", total / 60, total % 60)))
        }
        if let sizeLabel = sizeLabel, !sizeLabel.isEmpty {
            result.append(("internaldrive", sizeLabel))
        }
        if let stats = statistics {
            if let v = stats.likeCount, v > 0 { result.append(("heart", StatsRow.formatNumber(v))) }
            if let v = stats.commentCount, v > 0 { result.append(("bubble.left", StatsRow.formatNumber(v))) }
            if let v = stats.shareCount, v > 0 { result.append(("square.and.arrow.up", StatsRow.formatNumber(v))) }
            if let v = stats.playCount, v > 0 { result.append(("eye", StatsRow.formatNumber(v))) }
        }
        return result
    }

    var body: some View {
        if chips.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                        StatChip(icon: chip.icon, text: chip.text)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    static func formatNumber(_ count: Int64) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

struct StatChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(AppTheme.onSurfaceVariant)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.surfaceVariant.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
