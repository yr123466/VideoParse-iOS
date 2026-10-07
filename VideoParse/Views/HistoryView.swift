import SwiftUI
import UIKit

// MARK: - 历史与收藏页（对应 Android HistoryScreen）

struct HistoryView: View {
    @ObservedObject var viewModel: VideoParseViewModel
    let onNavigateToParse: () -> Void

    @State private var showClearDialog = false

    private let tabs = ["全部", "我的收藏", "视频", "图集"]
    private let platformFilters: [(id: String?, label: String)] = [
        (nil, "全部平台"),
        ("douyin", "抖音"),
        ("bilibili", "B站"),
        ("kuaishou", "快手"),
        ("xiaohongshu", "小红书"),
        ("tiktok", "TikTok")
    ]

    var body: some View {
        VStack(spacing: 8) {
            searchHeader
            tabRow
            platformChips
            historyList
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.background.ignoresSafeArea())
        .alert("清空历史记录", isPresented: $showClearDialog) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) { viewModel.clearAllHistory() }
        } message: {
            Text("确定要清除所有解析历史吗？此操作不可撤销。")
        }
    }

    // MARK: 搜索栏

    private var searchHeader: some View {
        HStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.onSurfaceVariant)
                TextField("搜索历史标题、作者、平台…", text: $viewModel.searchQuery)
                    .font(.system(size: 13))
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.setSearchQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.outlineVariant, lineWidth: 1)
            )

            if !viewModel.filteredHistory.isEmpty {
                Button {
                    showClearDialog = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.error)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: 分类 Tab

    private var tabRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                Button {
                    viewModel.setHistoryTab(index)
                } label: {
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: viewModel.historyTab == index ? .bold : .regular))
                            .foregroundColor(viewModel.historyTab == index ? AppTheme.primary : AppTheme.onSurfaceVariant)
                        Rectangle()
                            .fill(viewModel.historyTab == index ? AppTheme.primary : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    // MARK: 平台筛选

    private var platformChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(platformFilters, id: \.label) { filter in
                    let isSelected = viewModel.selectedPlatformFilter == filter.id
                    Button {
                        viewModel.setPlatformFilter(isSelected ? nil : filter.id)
                    } label: {
                        Text(filter.label)
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? AppTheme.primaryContainer : AppTheme.surfaceVariant)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(AppTheme.outlineVariant.opacity(0.6), lineWidth: isSelected ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: 列表

    @ViewBuilder
    private var historyList: some View {
        if viewModel.filteredHistory.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.outlineVariant)
                Text("暂无匹配的解析记录")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredHistory) { item in
                        HistoryItemCard(
                            item: item,
                            onReParse: {
                                viewModel.reparseFromHistory(item)
                                onNavigateToParse()
                            },
                            onToggleFavorite: {
                                viewModel.toggleFavorite(id: item.id, currentFavorite: item.isFavorite)
                            },
                            onDelete: {
                                viewModel.deleteHistory(id: item.id)
                            },
                            onCopyLink: {
                                let link = item.videoUrl.isEmpty ? item.targetUrl : item.videoUrl
                                UIPasteboard.general.string = link
                                viewModel.showToast("视频直链 已复制到剪贴板")
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - 历史条目卡

struct HistoryItemCard: View {
    let item: ParseHistoryItem
    let onReParse: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    let onCopyLink: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RemoteImage(urlString: item.coverUrl, contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    PlatformBadge(platform: item.platform)
                    Text(item.authorName)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                        .lineLimit(1)
                }

                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 2) {
                    Text(HistoryItemCard.dateString(item.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.onSurfaceVariant.opacity(0.7))
                    if !item.sizeLabel.isEmpty {
                        Text(" · \(item.sizeLabel)")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.onSurfaceVariant.opacity(0.7))
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 6) {
                Button(action: onToggleFavorite) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(item.isFavorite ? AppTheme.error : AppTheme.onSurfaceVariant)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Button(action: onCopyLink) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.outlineVariant)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onReParse)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    static func dateString(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        return formatter.string(from: date)
    }
}
