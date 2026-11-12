import SwiftUI

struct LibraryView: View {

    @EnvironmentObject private var store: AppStore

    private let tabs = ["全部素材", "视频", "图文图集", "背景音乐", "我的收藏"]
    private let platformFilters: [(String?, String)] = [
        (nil, "全部平台"),
        ("douyin", "抖音"),
        ("bilibili", "B站"),
        ("kuaishou", "快手"),
        ("xiaohongshu", "小红书"),
        ("music", "音乐库"),
        ("tiktok", "TikTok")
    ]

    @State private var detailItem: HistoryItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 11) {
                header
                SearchField(text: $store.searchQuery, placeholder: "搜索素材标题、作者或平台…")
                tabBar
                platformBar

                let list = store.filteredHistory
                if list.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 9) {
                        ForEach(list) { item in
                            LibraryRow(item: item) {
                                detailItem = item
                            }
                        }
                    }
                }

                Text("共 \(store.history.count) 条记录 · 视频 \(store.videoCount) · 图文 \(store.imageCount) · 音乐 \(store.audioCount)")
                    .font(.system(size: 9.5))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 15)
            .padding(.top, 13)
            .padding(.bottom, 26)
        }
        .background(Color.clear)
        .sheet(item: $detailItem) { item in
            LibraryDetailSheet(item: item)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("素材库")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(store.history.count)")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Theme.primary)
                        .clipShape(Capsule())
                }
                Text("一键直放视频 · 图集缩放预览 · 背景音乐收藏")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer(minLength: 0)

            if !store.history.isEmpty {
                Button {
                    store.clearHistory()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "trash").font(.system(size: 9, weight: .bold))
                        Text("清空").font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundColor(Theme.coral)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.coral.opacity(0.09))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                    Button {
                        store.libraryTab = index
                    } label: {
                        VStack(spacing: 5) {
                            Text(title)
                                .font(.system(size: 12.5, weight: store.libraryTab == index ? .bold : .medium))
                                .foregroundColor(store.libraryTab == index ? Theme.primary : Theme.textSecondary)
                            Capsule()
                                .fill(store.libraryTab == index ? Theme.primary : Color.clear)
                                .frame(height: 2.5)
                                .frame(width: 22)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var platformBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(platformFilters.enumerated()), id: \.offset) { pair in
                    let key = pair.element.0
                    let selected = store.platformFilter == key
                    Button {
                        store.platformFilter = selected ? nil : key
                    } label: {
                        Text(pair.element.1)
                            .font(.system(size: 10.5, weight: selected ? .bold : .medium))
                            .foregroundColor(selected ? .white : Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5.5)
                            .background(
                                Capsule().fill(selected ? AnyShapeStyle(Theme.primary) : AnyShapeStyle(Theme.surface))
                            )
                            .overlay(Capsule().stroke(selected ? Color.clear : Theme.stroke, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var emptyState: some View {
        CardBox(padding: 26) {
            VStack(spacing: 9) {
                ZStack {
                    Circle().fill(Theme.primary.opacity(0.08)).frame(width: 56, height: 56)
                    Image(systemName: "tray")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.primary.opacity(0.75))
                }
                Text("暂无匹配的媒体素材")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("在解析界面解析视频、图集或下载音乐后即可在此集中查看")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    store.libraryTab = 0
                } label: {
                    Text("去解析一条")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(Theme.primary.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 3)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
    }

// MARK: - 素材行

struct LibraryRow: View {
    @EnvironmentObject private var store: AppStore

    let item: HistoryItem
    let onOpen: () -> Void

    var body: some View {
        CardBox(padding: 9) {
            HStack(spacing: 11) {
                ZStack {
                    RemoteImage(url: item.coverUrl, contentMode: .fill)
                        .frame(width: 78, height: 78)
                    Color.black.opacity(0.18)
                    ZStack {
                        Circle().fill(Color.black.opacity(0.45)).frame(width: 30, height: 30)
                        Image(systemName: playIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 78, height: 78)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture(perform: onOpen)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        PlatformBadge(platform: item.platform)
                        Text(item.displayAuthor)
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.textTertiary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.amber)
                        }
                    }

                    Text(item.displayTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 5) {
                        Text(item.typeLabel)
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Theme.primary.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                        if !Fmt.duration(item.duration).isEmpty {
                            InfoChip(icon: "clock", text: Fmt.duration(item.duration))
                        }
                        if !item.sizeLabel.isEmpty {
                            InfoChip(icon: "internaldrive", text: item.sizeLabel)
                        }
                        Spacer(minLength: 0)
                    }
                }

                Menu {
                    Button {
                        store.toggleFavorite(item)
                    } label: {
                        Label(item.isFavorite ? "取消收藏" : "加入收藏", systemImage: "star")
                    }
                    Button {
                        Clipboard.copy(item.targetUrl)
                        store.showToast("链接已复制")
                    } label: {
                        Label("复制原链接", systemImage: "doc.on.doc")
                    }
                    Button {
                        store.loadHistoryItem(item)
                    } label: {
                        Label("重新解析", systemImage: "arrow.clockwise")
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.delete(item)
                    } label: {
                        Label("删除记录", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                        .frame(width: 26, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onTapGesture(perform: onOpen)
    }

    private var playIcon: String {
        if item.mediaType == "audio" { return "play.fill" }
        if item.isImageMedia { return "photo" }
        return "play.fill"
    }
}

// MARK: - 素材详情

struct LibraryDetailSheet: View {

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let item: HistoryItem

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 13) {
                media
                infoBlock
                actions
                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color.clear)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Theme.surfaceAlt)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 14)
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var media: some View {
        if item.mediaType == "audio" {
            CardBox(padding: 14) {
                AudioPlayCard(
                    title: item.displayTitle,
                    subtitle: item.displayAuthor,
                    cover: item.coverUrl,
                    url: item.audioUrl
                )
            }
        } else if item.isImageMedia && !item.imageList.isEmpty {
            ImagePager(images: item.imageList, liveVideos: item.liveVideos ?? [], aspect: 0.82)
        } else if !item.videoUrl.isEmpty {
            VideoPlayerBox(
                url: item.videoUrl,
                cover: item.coverUrl,
                title: item.displayTitle,
                copyText: item.videoUrl,
                shareItems: {
                    [URL(string: item.videoUrl)].compactMap { $0 }
                },
                onDownload: {
                    store.dismissImmersivePlayer()
                    store.downloadVideo(url: item.videoUrl, title: item.displayTitle)
                },
                autoFullScreen: store.autoFullScreenPlayback
            )
        } else if !item.coverUrl.isEmpty {
            RemoteImage(url: item.coverUrl, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var infoBlock: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    PlatformBadge(platform: item.platform)
                    InfoChip(icon: item.isFavorite ? "star.fill" : "star", text: item.quality.isEmpty ? "原画" : item.quality)
                    if !Fmt.duration(item.duration).isEmpty {
                        InfoChip(icon: "clock", text: Fmt.duration(item.duration))
                    }
                    Spacer(minLength: 4)
                    Text(Fmt.relative(item.timestamp))
                        .font(.system(size: 9.5))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                        .fixedSize()
                }

                Text(item.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    if !item.authorAvatar.isEmpty {
                        RemoteImage(url: item.authorAvatar, contentMode: .fill)
                            .frame(width: 18, height: 18)
                            .clipShape(Circle())
                    }
                    Text(item.displayAuthor)
                        .font(.system(size: 10.5))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    if !item.sizeLabel.isEmpty {
                        Text(item.sizeLabel)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                if !item.desc.isEmpty {
                    Text(item.desc)
                        .font(.system(size: 10.5))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var actions: some View {
        CardBox(padding: 12) {
            VStack(spacing: 9) {
                HStack(spacing: 8) {
                    Button {
                        download()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "square.and.arrow.down").font(.system(size: 11, weight: .bold))
                            Text(downloadTitle).font(.system(size: 12.5, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Theme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        store.toggleFavorite(item)
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(item.isFavorite ? Theme.amber : Theme.textSecondary)
                            .frame(width: 44, height: 42)
                            .background(Theme.surfaceAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack(spacing: 8) {
                    smallButton(icon: "doc.on.doc", title: "复制直链") {
                        Clipboard.copy(item.mediaType == "audio" ? item.audioUrl : (item.isImageMedia ? item.imageList.first ?? "" : item.videoUrl))
                        store.showToast("直链已复制")
                    }
                    smallButton(icon: "square.and.arrow.up", title: "分享") {
                        var items: [Any] = []
                        if item.mediaType == "audio", let u = URL(string: item.audioUrl) {
                            items = [u]
                        } else if item.isImageMedia {
                            items = item.imageList
                        } else if let u = URL(string: item.videoUrl) {
                            items = [u]
                        }
                        if !items.isEmpty { store.share(items) }
                    }
                    smallButton(icon: "arrow.clockwise", title: "重新解析") {
                        dismiss()
                        store.loadHistoryItem(item)
                    }
                }

                if !livePairs.isEmpty {
                    HStack(spacing: 8) {
                        smallButton(icon: "livephoto", title: "存实况到相册") {
                            store.saveLivePhotosToAlbum(pairs: livePairs)
                        }
                        smallButton(icon: "square.and.arrow.down", title: "下载动图") {
                            store.downloadLivePhotos(urls: item.liveVideoList, title: item.displayTitle)
                        }
                    }
                }
            }
        }
    }

    private var downloadTitle: String {
        if item.mediaType == "audio" { return "下载音频" }
        if item.isLiveMedia { return "下载动图" }
        if item.isImageMedia { return "下载全部图片" }
        return "下载无水印视频"
    }

    private var livePairs: [LivePhotoItem] {
        let imgs = item.imageList
        let vids = item.liveVideos ?? []
        var out: [LivePhotoItem] = []
        for (index, image) in imgs.enumerated() where index < vids.count && !vids[index].isEmpty {
            out.append(LivePhotoItem(image: image, video: vids[index]))
        }
        return out
    }

    private func download() {
        if item.mediaType == "audio" {
            store.downloadAudio(url: item.audioUrl, title: item.displayTitle)
        } else if item.isLiveMedia {
            store.downloadLivePhotos(urls: item.liveVideoList, title: item.displayTitle)
        } else if item.isImageMedia {
            store.downloadAllImages(urls: item.imageList, title: item.displayTitle)
        } else {
            store.downloadVideo(url: item.videoUrl, title: item.displayTitle)
        }
    }

    private func smallButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                Text(title).font(.system(size: 10.5, weight: .medium))
            }
            .foregroundColor(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(Theme.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
}
