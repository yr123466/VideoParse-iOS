import SwiftUI
import AVKit

// MARK: - 视频播放

struct VideoPlayerBox: View {
    let url: String
    let cover: String
    var aspect: CGFloat = 16.0 / 9.0

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black
            if let player = player {
                VideoPlayer(player: player)
            } else {
                RemoteImage(url: cover)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                Color.black.opacity(0.28)

                Button {
                    start()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.92))
                            .frame(width: 62, height: 62)
                            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: 0x0369A1))
                            .offset(x: 2)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 9))
                        Text("点击播放无水印原片")
                            .font(.system(size: 10, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(.white.opacity(0.92))
                    .padding(10)
                }
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onChange(of: url) { _ in
            player?.pause()
            player = nil
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func start() {
        guard let link = URL(string: url) else { return }
        let next = AVPlayer(url: link)
        player = next
        next.play()
    }
}

// MARK: - 动图（实况）循环播放

final class LoopingPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    func play(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = true
        queue.actionAtItemEnd = .advance
        looper = AVPlayerLooper(player: queue, templateItem: item)
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.masksToBounds = true
        queue.play()
        player = queue
    }

    func stop() {
        player?.pause()
        looper?.disableLooping()
        looper = nil
        playerLayer.player = nil
        player = nil
    }
}

/// 静音循环播放的实况动图（不拦截手势，交给外层翻页/全屏）
struct LoopingVideoView: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView()
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        guard let link = URL(string: url) else { return }
        if context.coordinator.current != url {
            context.coordinator.current = url
            uiView.play(url: link)
        }
    }

    static func dismantleUIView(_ uiView: LoopingPlayerUIView, coordinator: Coordinator) {
        uiView.stop()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var current: String?
    }
}

// MARK: - 图片翻页（支持实况动图）

struct ImagePager: View {
    let images: [String]
    var liveVideos: [String] = []
    var aspect: CGFloat = 0.82
    var corner: CGFloat = 14

    @State private var index = 0
    @State private var showViewer = false

    private func liveURL(at offset: Int) -> String? {
        guard offset >= 0, offset < liveVideos.count else { return nil }
        let link = liveVideos[offset]
        return link.isEmpty ? nil : link
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $index) {
                ForEach(Array(images.enumerated()), id: \.offset) { offset, link in
                    ZStack {
                        RemoteImage(url: link, contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()

                        if offset == index, let video = liveURL(at: offset) {
                            LoopingVideoView(url: video)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        if liveURL(at: offset) != nil {
                            HStack(spacing: 3) {
                                Image(systemName: "livephoto.play")
                                    .font(.system(size: 9, weight: .bold))
                                Text("动图")
                                    .font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Capsule())
                            .padding(9)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showViewer = true }
                    .tag(offset)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            if images.count > 1 {
                Text("\(index + 1) / \(images.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(10)
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .fullScreenCover(isPresented: $showViewer) {
            ImageViewer(images: images, liveVideos: liveVideos, startIndex: index)
        }
    }
}

struct ImageViewer: View {
    let images: [String]
    var liveVideos: [String] = []
    @State var startIndex: Int
    @Environment(\.dismiss) private var dismiss

    private func liveURL(at offset: Int) -> String? {
        guard offset >= 0, offset < liveVideos.count else { return nil }
        let link = liveVideos[offset]
        return link.isEmpty ? nil : link
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $startIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { offset, link in
                    ZStack {
                        if let video = liveURL(at: offset) {
                            LoopingVideoView(url: video)
                                .allowsHitTesting(false)
                        } else {
                            ZoomableImage(url: link)
                        }
                    }
                    .tag(offset)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            VStack {
                HStack {
                    Text("\(startIndex + 1) / \(images.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    if liveURL(at: startIndex) != nil {
                        Text("动图")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.20))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                Spacer()
            }
        }
        .statusBarHidden(true)
    }
}

struct ZoomableImage: View {
    let url: String
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1

    var body: some View {
        RemoteImage(url: url, contentMode: .fit)
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = min(max(baseScale * value, 1), 5)
                    }
                    .onEnded { _ in
                        baseScale = scale
                        if scale < 1 { scale = 1; baseScale = 1 }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if scale > 1 {
                        scale = 1
                        baseScale = 1
                    } else {
                        scale = 2.5
                        baseScale = 2.5
                    }
                }
            }
    }
}

// MARK: - 音频播放

final class AudioPlaybackModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var current: Double = 0
    @Published var duration: Double = 0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var loadedURL: String?

    var progress: Double {
        duration > 0 ? min(1, max(0, current / duration)) : 0
    }

    func load(_ url: String) {
        guard loadedURL != url, let link = URL(string: url) else { return }
        cleanup()
        let item = AVPlayerItem(url: link)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        loadedURL = url
        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.4, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            let total = item.duration.seconds
            if total.isFinite && total > 0 { self.duration = total }
            let seconds = time.seconds
            if seconds.isFinite { self.current = seconds }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isPlaying = false
            self.current = 0
            self.player?.seek(to: .zero)
        }
    }

    func toggle(_ url: String) {
        load(url)
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player?.pause()
        isPlaying = false
    }

    private func cleanup() {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
        if let end = endObserver {
            NotificationCenter.default.removeObserver(end)
        }
        player?.pause()
        timeObserver = nil
        endObserver = nil
        player = nil
    }

    deinit {
        cleanup()
    }
}

struct AudioPlayCard: View {
    let title: String
    let subtitle: String
    let cover: String
    let url: String
    var tint: Color = Theme.amber

    @StateObject private var model = AudioPlaybackModel()

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Theme.amber.opacity(0.85), Theme.coral.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    Image(systemName: "music.note")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title.isEmpty ? "背景原声音乐" : title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(subtitle.isEmpty ? "原声音频" : subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    model.toggle(url)
                } label: {
                    ZStack {
                        Circle().fill(tint).frame(width: 42, height: 42)
                        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: model.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceAlt).frame(height: 4)
                        Capsule()
                            .fill(tint)
                            .frame(width: max(0, geo.size.width * model.progress), height: 4)
                    }
                }
                .frame(height: 4)

                HStack {
                    Text(Fmt.duration(model.current).isEmpty ? "00:00" : Fmt.duration(model.current))
                    Spacer()
                    Text(Fmt.duration(model.duration).isEmpty ? "--:--" : Fmt.duration(model.duration))
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textTertiary)
            }
        }
        .onDisappear { model.stop() }
    }
}

// MARK: - 清晰度选择

struct QualitySelector: View {
    let items: [VideoBackupItem]
    let activeLabel: String
    let onSelect: (VideoBackupItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10, weight: .semibold))
                Text("可选清晰度")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(Theme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        let selected = item.title == activeLabel
                        Button {
                            onSelect(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 11.5, weight: .bold))
                                let sub = item.sizeLabel ?? Fmt.size(item.size)
                                if !sub.isEmpty {
                                    Text(sub)
                                        .font(.system(size: 9.5))
                                        .opacity(0.8)
                                }
                            }
                            .foregroundColor(selected ? .white : Theme.textPrimary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(selected ? AnyShapeStyle(Theme.primary) : AnyShapeStyle(Theme.surfaceAlt))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(selected ? Color.clear : Theme.stroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - 数据统计

struct StatsRow: View {
    let stats: StatisticsInfo?

    var body: some View {
        if let stats = stats {
            HStack(spacing: 16) {
                item(icon: "heart.fill", value: stats.likeTotal, tint: Theme.coral)
                item(icon: "bubble.left.fill", value: stats.commentCount, tint: Theme.primary)
                item(icon: "star.fill", value: stats.collectCount, tint: Theme.amber)
                item(icon: "play.fill", value: stats.playCount, tint: Theme.indigo)
            }
        }
    }

    private func item(icon: String, value: Int64?, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(tint)
            Text(Fmt.count(value))
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
        }
    }
}
