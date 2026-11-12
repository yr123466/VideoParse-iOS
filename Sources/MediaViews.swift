import SwiftUI
import AVKit

// MARK: - 视频播放（点击进入沉浸式全屏）

struct VideoPlayerBox: View {
    let url: String
    let cover: String
    var aspect: CGFloat = 16.0 / 9.0
    var title: String = ""
    var copyText: String = ""
    var shareItems: () -> [Any] = { [] }
    var onDownload: (() -> Void)? = nil
    /// true = 点卡片直接全屏；false = 点卡片在卡片内直接播放
    var autoFullScreen: Bool = false

    @State private var showImmersive = false
    @State private var player = AVPlayer()
    @State private var inlineActive = false
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            Color.black

            if inlineActive {
                PlayerSurface(player: player)
            } else {
                RemoteImage(url: cover)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                Color.black.opacity(0.25)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.94))
                        .frame(width: 62, height: 62)
                        .shadow(color: .black.opacity(0.28), radius: 14, y: 5)
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: 0x0369A1))
                        .offset(x: 2)
                }
            }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: openFullScreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Color.black.opacity(0.42))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(9)

                Spacer(minLength: 0)

                if inlineActive {
                    inlineControls
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "video.fill").font(.system(size: 9))
                        Text(autoFullScreen ? "点击全屏沉浸播放" : "点击播放 · 右上角全屏")
                            .font(.system(size: 10, weight: .medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(.white.opacity(0.94))
                    .padding(10)
                }
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: primaryTap)
        .onDisappear(perform: teardown)
        .onChange(of: showImmersive, perform: { showing in
            // 从全屏返回后继续卡片内播放
            if !showing && inlineActive {
                player.play()
                isPlaying = true
            }
        })
        .fullScreenCover(isPresented: $showImmersive) {
            ImmersiveVideoPlayer(
                url: url,
                cover: cover,
                title: title,
                copyText: copyText,
                shareItems: shareItems,
                onDownload: onDownload
            )
        }
    }

    // MARK: 卡片内控制条

    private var inlineControls: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.28)).frame(height: 2.5)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(0, geo.size.width * progress), height: 2.5)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let ratio = min(max(value.location.x / max(geo.size.width, 1), 0), 1)
                            progress = ratio
                        }
                        .onEnded { _ in
                            guard duration > 0 else { return }
                            player.seek(to: CMTime(seconds: progress * duration, preferredTimescale: 600))
                        }
                )
            }
            .frame(height: 14)

            HStack(spacing: 8) {
                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                Text("\(Fmt.duration(progress * duration)) / \(Fmt.duration(duration))")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .fixedSize()

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: 交互

    private func primaryTap() {
        guard !url.isEmpty else { return }
        if !inlineActive && autoFullScreen {
            openFullScreen()
            return
        }
        if inlineActive {
            togglePlay()
        } else {
            startInline()
        }
    }

    private func startInline() {
        guard let link = URL(string: url) else { return }
        let item = AVPlayerItem(url: link)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true
        inlineActive = true

        if timeObserver == nil {
            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.3, preferredTimescale: 600),
                queue: .main
            ) { time in
                let total = item.duration.seconds
                if total.isFinite && total > 0 { duration = total }
                let current = time.seconds
                if current.isFinite, duration > 0 {
                    progress = min(max(current / duration, 0), 1)
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            isPlaying = false
            progress = 1
        }
    }

    private func togglePlay() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if progress >= 0.999 {
                player.seek(to: .zero)
                progress = 0
            }
            player.play()
            isPlaying = true
        }
    }

    private func openFullScreen() {
        guard !url.isEmpty else { return }
        if inlineActive {
            player.pause()
            isPlaying = false
        }
        showImmersive = true
    }

    private func teardown() {
        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let end = endObserver {
            NotificationCenter.default.removeObserver(end)
            endObserver = nil
        }
    }
}

// MARK: - 沉浸式全屏播放器

struct PlayerSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

final class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct ImmersiveVideoPlayer: View {
    let url: String
    let cover: String
    var title: String = ""
    var copyText: String = ""
    var shareItems: () -> [Any] = { [] }
    var onDownload: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var localShare: SharePayload? = nil
    @State private var hud: String? = nil
    @State private var hudTask: Task<Void, Never>? = nil

    @State private var player = AVPlayer()
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 0
    @State private var controlsVisible = true
    @State private var isSeeking = false
    @State private var timeObserver: Any?
    @State private var hideTask: Task<Void, Never>?
    @State private var dragY: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZStack {
                PlayerSurface(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if controlsVisible {
                            togglePlay()
                        } else {
                            revealControls()
                        }
                    }

                if !isPlaying {
                    Image(systemName: "play.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.4), radius: 12)
                        .allowsHitTesting(false)
                        .opacity(controlsVisible ? 1 : 0)
                }

                if controlsVisible {
                    controls
                        .transition(.opacity)
                }
            }
            .offset(y: dragY)
            .scaleEffect(max(0.82, 1 - dragY / 2600))
            .simultaneousGesture(dismissGesture)
        }
        .statusBarHidden(true)
        .overlay(alignment: .bottom) {
            if let hud = hud {
                Text(hud)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.62))
                    .clipShape(Capsule())
                    .padding(.bottom, 130)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .sheet(item: $localShare) { payload in
            ShareSheet(items: payload.items)
        }
        .onAppear(perform: setup)
        .onDisappear {
            player.pause()
            removeObserver()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
    }

    // MARK: 全面屏手势：下拉关闭

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                // 只接管明显的纵向下拉，横向拖动交给进度条
                guard abs(value.translation.height) > abs(value.translation.width) * 1.2 else { return }
                let h = value.translation.height
                dragY = h > 0 ? h : h / 4
            }
            .onEnded { value in
                let predicted = value.predictedEndTranslation.height
                guard abs(value.translation.height) > abs(value.translation.width) * 1.2 else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { dragY = 0 }
                    return
                }
                if dragY > 120 || predicted > 300 {
                    player.pause()
                    UIApplication.shared.isIdleTimerDisabled = false
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) { dragY = 0 }
                }
            }
    }

    // MARK: 控件

    private var controls: some View {
        VStack {
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                Text(title.isEmpty ? "无水印预览" : title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()

            VStack(spacing: 12) {
                HStack {
                    Text(Fmt.duration(isSeeking ? progress * duration : player.currentTime().seconds))
                    Spacer()
                    Text(Fmt.duration(duration))
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.25)).frame(height: 3)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, geo.size.width * progress), height: 3)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isSeeking = true
                                let ratio = min(max(value.location.x / geo.size.width, 0), 1)
                                progress = ratio
                            }
                            .onEnded { _ in
                                let target = CMTime(seconds: progress * duration, preferredTimescale: 600)
                                player.seek(to: target)
                                isSeeking = false
                                scheduleHide()
                            }
                    )
                }
                .frame(height: 18)

                HStack(spacing: 10) {
                    Button {
                        togglePlay()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    if !copyText.isEmpty {
                        circleButton(icon: "text.quote") {
                            Clipboard.copy(copyText)
                            showHUD("无水印直链已复制")
                        }
                    }
                    circleButton(icon: "square.and.arrow.up") {
                        let items = shareItems()
                        if items.isEmpty {
                            showHUD("暂无可分享内容")
                        } else {
                            localShare = SharePayload(items: items)
                            hideTaskCancel()
                        }
                    }
                    if let download = onDownload {
                        circleButton(icon: "arrow.down.to.line") {
                            // 先退出全屏，再交由外层弹出下载面板
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                download()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 26)
        }
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            scheduleHide()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.14))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: 播放控制

    private func setup() {
        guard let link = URL(string: url) else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        let item = AVPlayerItem(url: link)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.35, preferredTimescale: 600),
            queue: .main
        ) { time in
            if isSeeking { return }
            let total = item.duration.seconds
            if total.isFinite && total > 0 { duration = total }
            let current = time.seconds
            if current.isFinite, duration > 0 {
                progress = min(max(current / duration, 0), 1)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            isPlaying = false
            controlsVisible = true
        }

        scheduleHide()
    }

    private func togglePlay() {
        if isPlaying {
            player.pause()
            isPlaying = false
            controlsVisible = true
            hideTask?.cancel()
        } else {
            if progress >= 0.999 {
                player.seek(to: .zero)
                progress = 0
            }
            player.play()
            isPlaying = true
            scheduleHide()
        }
    }

    private func revealControls() {
        controlsVisible = true
        scheduleHide()
    }

    private func scheduleHide() {
        hideTask?.cancel()
        guard isPlaying else { return }
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation { controlsVisible = false }
            }
        }
    }

    private func showHUD(_ text: String) {
        hudTask?.cancel()
        withAnimation(.easeOut(duration: 0.18)) { hud = text }
        hudTask = Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.2)) { hud = nil }
            }
        }
    }

    private func hideTaskCancel() {
        hudTask?.cancel()
        hud = nil
    }

    private func removeObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        hideTask?.cancel()
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

final class AudioPlaybackModel: NSObject, ObservableObject {
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

        // 缓冲状态观察
        item.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new], context: nil)
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: nil)

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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if keyPath == "status" {
                self.isBuffering = (item.status == .unknown)
            } else if keyPath == "playbackBufferEmpty" {
                self.isBuffering = item.isPlaybackBufferEmpty
            } else if keyPath == "playbackLikelyToKeepUp" {
                self.isBuffering = !item.isPlaybackLikelyToKeepUp
            }
        }
    }

    private func cleanup() {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
        if let end = endObserver {
            NotificationCenter.default.removeObserver(end)
        }
        if let item = player?.currentItem {
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
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

// MARK: - 背景音乐行（含在线试听）

struct MusicRowView: View {
    let music: MusicInfo
    var title: String? = nil
    var author: String? = nil
    var cover: String? = nil
    var platform: String? = nil
    var onDownload: (String) -> Void

    @StateObject private var model = AudioPlaybackModel()

    var body: some View {
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

            // 在线试听按钮
            Button {
                if let url = music.url, !url.isEmpty {
                    model.toggle(url)
                }
            } label: {
                ZStack {
                    Circle().fill(Theme.amber).frame(width: 32, height: 32)
                    Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: model.isPlaying ? 0 : 1)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .overlay(alignment: .top) {
                if model.isBuffering {
                    ProgressView()
                        .controlSize(.mini)
                        .offset(y: -2)
                }
            }

            Button {
                if let url = music.url, !url.isEmpty {
                    onDownload(url)
                }
            } label: {
                Text("下载并收录")
            }
            .buttonStyle(SoftButtonStyle(tint: Theme.amber, filled: true))
        }
        .padding(9)
        .background(Theme.amber.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
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
            HStack(spacing: 14) {
                item(icon: "heart.fill", value: stats.likeTotal, tint: Theme.coral)
                item(icon: "bubble.left.fill", value: stats.commentCount, tint: Theme.primary)
                item(icon: "star.fill", value: stats.collectCount, tint: Theme.amber)
                item(icon: "play.fill", value: stats.playCount, tint: Theme.indigo)
                Spacer(minLength: 0)
            }
        }
    }

    private func item(icon: String, value: Int64?, tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(tint)
            Text(Fmt.count(value))
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .fixedSize()          // 关键：数字不换行、不压缩
        }
    }
}
