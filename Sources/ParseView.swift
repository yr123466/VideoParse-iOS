import SwiftUI

struct ParseView: View {

    @EnvironmentObject private var store: AppStore

    private var isLoading: Bool {
        if case .loading = store.parseState { return true }
        return false
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 13) {
                if store.clipboardHint {
                    clipboardBanner
                }
                hero
                inputCard
                parseButton
                sampleRow
                resultSection
                recentSection
                footerNote
            }
            .padding(.horizontal, 15)
            .padding(.top, 13)
            .padding(.bottom, 30)
        }
        .background(Color.clear)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: 剪贴板提示

    private var clipboardBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.primary)

            VStack(alignment: .leading, spacing: 1) {
                Text("检测到剪贴板中可能有视频链接")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("点击右侧按钮粘贴并解析")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                store.applyClipboardSuggestion()
            } label: {
                Text("一键解析")
            }
            .buttonStyle(SoftButtonStyle(tint: Theme.primary, filled: true))

            Button {
                store.dismissClipboardSuggestion()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .padding(5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(11)
        .background(Theme.primary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Theme.primary.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: 顶部横幅

    private var hero: some View {
        CardBox(padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Text("全网短视频无水印解析")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Spacer(minLength: 0)
                    Text("第三方公开接口")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.primary.opacity(0.10))
                        .clipShape(Capsule())
                }

                Text("粘贴分享链接，一键获取视频 / 图集 / 背景音乐原画直链")
                    .font(.system(size: 11.5))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    heroStat(value: "33+", label: "主流平台")
                    heroStat(value: "1080P", label: "高清原画")
                    heroStat(value: "0", label: "水印残留")
                }
                .padding(.top, 2)
            }
        }
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.primary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Theme.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: 输入

    private var inputCard: some View {
        CardBox(padding: 13) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    SectionTitle(icon: "link", title: "解析链接")
                    Spacer(minLength: 0)

                    Button {
                        store.pasteFromClipboard()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 9, weight: .bold))
                            Text("粘贴")
                        }
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.primary))

                    if !store.inputText.isEmpty {
                        Button {
                            store.clearInput()
                        } label: {
                            Text("清空")
                        }
                        .buttonStyle(SoftButtonStyle(tint: Theme.textSecondary))
                    }
                }

                ZStack(alignment: .topLeading) {
                    if store.inputText.isEmpty {
                        Text("粘贴抖音 / 快手 / 小红书 / B站等分享口令或网址…")
                            .font(.system(size: 12.5))
                            .foregroundColor(Theme.textTertiary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 11)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $store.inputText)
                        .font(.system(size: 12.5))
                        .foregroundColor(Theme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(height: 88)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                }
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
            }
        }
    }

    private var parseButton: some View {
        Button {
            store.parse()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                }
                Text(isLoading ? "解析中…" : "立即解析")
            }
        }
        .buttonStyle(PrimaryActionStyle(enabled: !isLoading))
        .disabled(isLoading)
    }

    // MARK: 示例

    private var sampleRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("快速测试示例：")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(Theme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(["douyin", "bilibili", "kuaishou", "xiaohongshu"], id: \.self) { id in
                        if let info = SupportedPlatforms.info(id) {
                            Button {
                                store.inputText = info.sampleUrl
                                store.parse(info.sampleUrl)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(info.emoji).font(.system(size: 10))
                                    Text(info.name).font(.system(size: 10.5, weight: .medium))
                                }
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 结果

    @ViewBuilder
    private var resultSection: some View {
        switch store.parseState {
        case .idle:
            idleCard
        case .loading:
            loadingCard
        case .failure(let message):
            failureCard(message)
        case .success(let response):
            if let data = response.data {
                ResultCard(response: response, data: data)
            } else {
                failureCard("接口未返回有效数据")
            }
        }
    }

    private var idleCard: some View {
        CardBox(padding: 22) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(Theme.primary.opacity(0.10)).frame(width: 54, height: 54)
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Theme.primary)
                }
                Text("准备就绪")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("复制视频分享链接后，粘贴至上方即可极速解析无水印高清内容")
                    .font(.system(size: 11.5))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var loadingCard: some View {
        CardBox(padding: 24) {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.1)
                    .tint(Theme.primary)
                Text("正在请求无水印高清源…")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("连接云端解析节点中，通常 3-10 秒完成")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func failureCard(_ message: String) -> some View {
        CardBox(padding: 18) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.coral)
                    Text("解析未能完成")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer(minLength: 0)
                }
                Text(message)
                    .font(.system(size: 11.5))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Button {
                        store.retry()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise").font(.system(size: 9, weight: .bold))
                            Text("重试解析").font(.system(size: 11.5))
                        }
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.primary, filled: true))
                    Spacer()
                }
            }
        }
    }

    // MARK: 最近记录

    private var recentSection: some View {
        VStack(spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                Text("解析记录")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("\(store.history.count)")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                Button {
                    store.selectedTab = 1
                } label: {
                    HStack(spacing: 3) {
                        Text("进入素材库").font(.system(size: 10.5, weight: .semibold))
                        Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(Theme.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            if store.history.isEmpty {
                CardBox(padding: 18) {
                    VStack(spacing: 6) {
                        Text("暂无解析记录")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("解析视频或图集后，记录会自动在此呈现并同步收录至素材库")
                            .font(.system(size: 10.5))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 9) {
                    ForEach(Array(store.history.prefix(3))) { item in
                        RecentRow(item: item)
                    }
                }
            }

            if store.history.count > 3 {
                Button {
                    store.selectedTab = 1
                } label: {
                    Text("查看全部 \(store.history.count) 条素材与历史 →")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.primary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 4)
    }

}

// MARK: - 解析结果卡片

struct ResultCard: View {

    @EnvironmentObject private var store: AppStore

    let response: ParseResponse
    let data: ParseData

    private var images: [String] { data.extractAllImages() }
    private var isImagePost: Bool { data.isImagePost }
    private var isAudioOnly: Bool {
        data.type == "audio" || (data.primaryVideoUrl.isEmpty && data.extractAudioUrl() != nil && images.isEmpty)
    }
    private var videoAspect: CGFloat {
        guard let w = data.width, let h = data.height, w > 0, h > 0 else { return 16.0 / 9.0 }
        let ratio = CGFloat(w) / CGFloat(h)
        return min(max(ratio, 0.6), 2.2)
    }
    private var imageAspect: CGFloat {
        guard let w = data.width, let h = data.height, w > 0, h > 0 else { return 0.82 }
        let ratio = CGFloat(w) / CGFloat(h)
        return min(max(ratio, 0.62), 1.6)
    }
    private var activeURL: String {
        store.activeVideoUrl.isEmpty ? data.primaryVideoUrl : store.activeVideoUrl
    }

    var body: some View {
        CardBox(padding: 13) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if isImagePost {
                    ImagePager(images: images, liveVideos: data.alignedLiveVideos(), aspect: imageAspect)
                } else if isAudioOnly {
                    AudioPlayCard(
                        title: data.getEffectiveMusic()?.title ?? data.title ?? "背景原声音乐",
                        subtitle: data.author?.name ?? "原声音频",
                        cover: data.cover ?? "",
                        url: data.extractAudioUrl() ?? ""
                    )
                } else if !activeURL.isEmpty {
                    VideoPlayerBox(
                        url: activeURL,
                        cover: data.cover ?? "",
                        aspect: videoAspect,
                        title: data.title ?? "",
                        copyText: activeURL,
                        shareItems: {
                            [URL(string: activeURL ?? "")].compactMap { $0 }
                        },
                        onDownload: {
                            store.dismissImmersivePlayer()
                            store.downloadVideo(url: activeURL, title: data.title ?? "video")
                        }
                    )
                }

                titleBlock

                if data.videoBackup.count > 1 && !isImagePost && !isAudioOnly {
                    Divider().background(Theme.stroke)
                    QualitySelector(
                        items: data.videoBackup,
                        activeLabel: store.activeQuality
                    ) { item in
                        store.selectQuality(item)
                        store.showToast("已切换至 \(item.title)")
                    }
                }

                Divider().background(Theme.stroke)

                actionGrid

                if let music = data.getEffectiveMusic(), !isAudioOnly {
                    musicRow(music)
                }
            }
        }
    }

    private var header: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                PlatformBadge(platform: response.platform ?? SupportedPlatforms.detect(data.url ?? ""))
                if data.isLive {
                    InfoChip(icon: "livephoto.play", text: "实况动图", tint: Theme.coral)
                } else {
                    InfoChip(icon: "film", text: data.primaryQuality)
                }
                if !Fmt.duration(data.duration).isEmpty {
                    InfoChip(icon: "clock", text: Fmt.duration(data.duration))
                }
                let sizeText = data.sizeLabel ?? Fmt.size(data.size)
                if !sizeText.isEmpty {
                    InfoChip(icon: "internaldrive", text: sizeText)
                }
            }
            .padding(.vertical, 1)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(data.title ?? data.desc ?? "未命名作品")
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            // 作者 + 发布时间（各自单行，过长自动截断）
            HStack(spacing: 7) {
                if let avatar = data.author?.avatar, !avatar.isEmpty {
                    RemoteImage(url: avatar, contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    Circle().fill(Theme.surfaceAlt)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.textTertiary)
                        )
                }

                Text(data.author?.name ?? "佚名")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)

                if let time = data.publishTime, !time.isEmpty {
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                    Text(time)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 0)
            }

            // 互动数据单独一行，避免与作者挤在一起
            if data.statistics != nil {
                StatsRow(stats: data.statistics)
            }
        }
    }

    private var actionGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            if isImagePost {
                ActionTile(icon: "square.and.arrow.down", title: "下载图片", subtitle: "\(images.count) 张", tint: Theme.primary) {
                    store.downloadAllImages(urls: images, title: data.title ?? "图集")
                }
                if data.isLive {
                    ActionTile(icon: "livephoto.play", title: "下载动图", subtitle: "\(data.liveVideoList().count) 个", tint: Theme.coral) {
                        store.downloadLivePhotos(urls: data.liveVideoList(), title: data.title ?? "动图")
                    }
                    ActionTile(icon: "livephoto", title: "存实况", subtitle: "到相册", tint: Theme.green) {
                        store.saveLivePhotosToAlbum(pairs: data.livePhoto)
                    }
                }
                ActionTile(icon: "doc.on.doc", title: "复制图集", subtitle: "全部直链", tint: Theme.indigo) {
                    Clipboard.copy(images.joined(separator: "\n"))
                    store.showToast("已复制 \(images.count) 条图片直链")
                }
            } else if isAudioOnly {
                ActionTile(icon: "square.and.arrow.down", title: "下载音频", subtitle: "原声", tint: Theme.amber) {
                    store.downloadAudio(url: data.extractAudioUrl() ?? "", title: data.title ?? "音频")
                }
                ActionTile(icon: "doc.on.doc", title: "复制直链", subtitle: "音频地址", tint: Theme.indigo) {
                    Clipboard.copy(data.extractAudioUrl() ?? "")
                    store.showToast("音频直链已复制")
                }
            } else {
                ActionTile(icon: "square.and.arrow.down", title: "下载视频", subtitle: "无水印", tint: Theme.primary) {
                    store.downloadVideo(url: activeURL, title: data.title ?? "video")
                }
                ActionTile(icon: "doc.on.doc", title: "复制直链", subtitle: "视频地址", tint: Theme.indigo) {
                    Clipboard.copy(activeURL)
                    store.showToast("无水印直链已复制")
                }
                if !images.isEmpty {
                    ActionTile(icon: "photo.stack", title: "下载封面", subtitle: "首图", tint: Theme.purple) {
                        store.downloadImage(url: images.first ?? "", title: data.title ?? "cover")
                    }
                }
            }

            ActionTile(icon: "square.and.arrow.up", title: "分享", subtitle: "系统面板", tint: Theme.green) {
                var items: [Any] = []
                if isImagePost {
                    items = images
                } else {
                    let shareURL = isAudioOnly ? (data.extractAudioUrl() ?? "") : activeURL
                    if let url = URL(string: shareURL) { items = [url] }
                }
                if !items.isEmpty { store.share(items) }
            }

            ActionTile(icon: "text.alignleft", title: "复制文案", subtitle: "标题作者", tint: Theme.textSecondary) {
                let text = "\(data.title ?? "")\n作者：\(data.author?.name ?? "佚名")\n\(data.desc ?? "")"
                Clipboard.copy(text)
                store.showToast("文案信息已复制")
            }
        }
    }

    private func musicRow(_ music: MusicInfo) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "music.note")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.amber)
                .frame(width: 30, height: 30)
                .background(Theme.amber.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("背景原声音乐")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(music.title ?? "原声")
                    .font(.system(size: 9.5))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                if let url = music.url, !url.isEmpty {
                    store.downloadAudio(url: url, title: music.title ?? data.title ?? "音频")
                    store.saveAudioMaterial(
                        title: music.title ?? data.title ?? "背景原声音乐",
                        author: music.author ?? data.author?.name ?? "佚名",
                        audioUrl: url,
                        coverUrl: data.cover ?? "",
                        platform: response.platform ?? SupportedPlatforms.detect(data.url ?? ""),
                        originalInput: store.inputText
                    )
                }
            } label: {
                Text("下载并收录")
            }
            .buttonStyle(SoftButtonStyle(tint: Theme.amber, filled: true))
        }
        .padding(9)
        .background(Theme.amber.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

// MARK: - 小行动块

struct ActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    var tint: Color = Theme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 解析记录行

struct RecentRow: View {
    @EnvironmentObject private var store: AppStore
    let item: HistoryItem

    var body: some View {
        CardBox(padding: 9) {
            HStack(spacing: 10) {
                ZStack {
                    RemoteImage(url: item.coverUrl, contentMode: .fill)
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Image(systemName: item.mediaType == "audio" ? "music.note" : (item.isImageMedia ? "photo.stack" : "play.fill"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .frame(width: 58, height: 58)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(2)
                    HStack(spacing: 5) {
                        PlatformBadge(platform: item.platform)
                        Text(item.typeLabel)
                            .font(.system(size: 9))
                            .foregroundColor(Theme.textTertiary)
                        Text(Fmt.relative(item.timestamp))
                            .font(.system(size: 9))
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                Spacer(minLength: 0)

                VStack(spacing: 7) {
                    Button {
                        store.loadHistoryItem(item)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.primary)
                            .frame(width: 26, height: 26)
                            .background(Theme.primary.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        Clipboard.copy(item.targetUrl)
                        store.showToast("链接已复制")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(Theme.surfaceAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
