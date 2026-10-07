import SwiftUI

// MARK: - 支持平台目录页（对应 Android PlatformsScreen）

struct PlatformsView: View {
    @ObservedObject var viewModel: VideoParseViewModel
    let onNavigateToParse: () -> Void

    @State private var searchQuery = ""

    private var filteredPlatforms: [PlatformInfo] {
        if searchQuery.isEmpty {
            return SupportedPlatforms.displayList
        }
        return SupportedPlatforms.displayList.filter { platform in
            platform.name.localizedCaseInsensitiveContains(searchQuery) ||
            platform.enName.localizedCaseInsensitiveContains(searchQuery) ||
            platform.formats.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // 搜索栏
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.onSurfaceVariant)
                TextField("搜索支持的平台 (共33+主流平台)…", text: $searchQuery)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.outlineVariant, lineWidth: 1)
            )

            ScrollView {
                LazyVStack(spacing: 10) {
                    bannerHeader
                    ForEach(filteredPlatforms) { platform in
                        PlatformDirectoryCard(
                            platform: platform,
                            onTestClick: {
                                viewModel.fillSampleUrl(platform.sampleUrl)
                                onNavigateToParse()
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var bannerHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.onPrimaryContainer)

            VStack(alignment: .leading, spacing: 2) {
                Text("全网主流媒体平台聚合支持")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.onPrimaryContainer)
                Text("已集成 \(SupportedPlatforms.displayList.count)+ 媒体与短视频平台，自动识别去水印并提取原画直链")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.onPrimaryContainer.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.primaryContainer)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - 平台目录卡

struct PlatformDirectoryCard: View {
    let platform: PlatformInfo
    let onTestClick: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 62), spacing: 6, alignment: .leading)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: platform.colorHex).opacity(0.12))
                        .frame(width: 42, height: 42)
                    Text(platform.iconEmoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(platform.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.onSurface)
                        Text(platform.enName)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.onSurfaceVariant)
                    }
                    Text(platform.tips)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Button(action: onTestClick) {
                    HStack(spacing: 4) {
                        Text("测试")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(AppTheme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                ForEach(platform.formats, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.surfaceVariant.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}
