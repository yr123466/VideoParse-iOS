import SwiftUI

// MARK: - 解析结果卡（对应 Android ParseResultCard）

struct ParseResultCard: View {
    let data: ParseData
    let platform: String
    let activeVideoUrl: String
    let activeQuality: String
    @ObservedObject var viewModel: VideoParseViewModel

    @State private var isDescExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MediaHeaderInfo(
                title: data.title ?? "解析成功",
                author: data.author,
                platform: platform,
                publishTime: data.publishTime
            )

            Spacer().frame(height: 12)

            // 标题与文案
            let displayTitle = data.title ?? data.desc ?? ""
            if !displayTitle.isEmpty {
                Text(displayTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.onSurface)
                Spacer().frame(height: 6)
            }

            if let desc = data.desc, !desc.isEmpty, desc != data.title {
                VStack(alignment: .leading, spacing: 2) {
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                        .lineLimit(isDescExpanded ? nil : 2)
                        .onTapGesture { isDescExpanded.toggle() }

                    if desc.count > 60 {
                        Text(isDescExpanded ? "收起文案" : "查看全文")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .onTapGesture { isDescExpanded.toggle() }
                    }
                }
                Spacer().frame(height: 8)
            }

            StatsRow(
                statistics: data.extra?.statistics,
                duration: data.duration,
                sizeLabel: data.sizeLabel
            )

            Spacer().frame(height: 14)

            // 媒体预览
            let liveImages = (data.livePhoto ?? []).compactMap { $0.image }
            let allImages = data.allImages
            let effectiveVideo = activeVideoUrl.isEmpty ? data.primaryVideoURL : activeVideoUrl

            MediaPreviewCard(
                videoUrl: effectiveVideo.isEmpty ? nil : effectiveVideo,
                coverUrl: data.cover ?? liveImages.first ?? allImages.first,
                images: allImages,
                music: data.music
            )

            // 清晰度切换
            if let backups = data.videoBackup, !backups.isEmpty {
                Spacer().frame(height: 12)
                QualitySelector(
                    defaultQuality: data.quality ?? "原画",
                    backupList: backups,
                    activeQuality: activeQuality,
                    onQualitySelected: { url, label in
                        viewModel.selectQuality(url: url, qualityLabel: label)
                    }
                )
            }

            Spacer().frame(height: 16)
            Divider()
                .background(AppTheme.outlineVariant.opacity(0.5))
            Spacer().frame(height: 16)

            ActionButtonsView(
                data: data,
                activeVideoUrl: activeVideoUrl,
                viewModel: viewModel
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}
