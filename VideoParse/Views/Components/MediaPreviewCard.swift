import SwiftUI
import AVKit
import UIKit

// MARK: - 媒体预览卡（对应 Android MediaPreviewCard）
// 视频播放 / 多图轮播 / 背景音乐试听

struct MediaPreviewCard: View {
    let videoUrl: String?
    let coverUrl: String?
    let images: [String]
    let music: MusicInfo?

    @State private var isPlayingVideo = false

    private var hasVideo: Bool {
        return !(videoUrl ?? "").isEmpty
    }

    var body: some View {
        VStack(spacing: 10) {
            if !images.isEmpty && !hasVideo {
                ImageGalleryView(images: images)
            } else if let videoUrl = videoUrl, !videoUrl.isEmpty {
                videoCard(videoUrl: videoUrl)
            }

            if let music = music, let url = music.url, !url.isEmpty {
                MusicPreviewBar(music: music)
            }
        }
    }

    @ViewBuilder
    private func videoCard(videoUrl: String) -> some View {
        ZStack {
            AppTheme.surfaceVariant

            if isPlayingVideo, let url = URL(string: videoUrl) {
                VideoPlayerView(url: url)
            } else {
                RemoteImage(urlString: coverUrl, contentMode: .fill)
                    .clipped()

                Color.black.opacity(0.35)

                Button {
                    isPlayingVideo = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                        Image(systemName: "play.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            openExternally(videoUrl)
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func openExternally(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - 多图轮播

struct ImageGalleryView: View {
    let images: [String]
    @State private var currentIndex = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                    RemoteImage(urlString: url, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.surfaceVariant)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            Text("\(currentIndex + 1) / \(images.count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(12)
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - 背景音乐试听条

struct MusicPreviewBar: View {
    let music: MusicInfo

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isLoading = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryContainer)
                    .frame(width: 40, height: 40)
                Image(systemName: "music.note")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.onPrimaryContainer)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(music.title ?? "背景原声音乐")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.onSurface)
                    .lineLimit(1)
                Text(music.author ?? "未知作者")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .frame(width: 28, height: 28)
            } else {
                Button {
                    togglePlay()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppTheme.surfaceVariant.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onDisappear {
            player?.pause()
            player = nil
            isPlaying = false
        }
    }

    private func togglePlay() {
        guard let urlString = music.url, let url = URL(string: urlString) else { return }

        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        if let player = player {
            player.play()
            isPlaying = true
            return
        }

        isLoading = true
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        newPlayer.play()
        isPlaying = true
        isLoading = false

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
        }
    }
}

// MARK: - AVPlayer 封装（对应 Android VideoView）

struct VideoPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerContainerView {
        return PlayerContainerView(url: url)
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}
}

final class PlayerContainerView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVPlayer?

    init(url: URL) {
        super.init(frame: .zero)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)

        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        playerLayer.player = newPlayer
        newPlayer.play()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    deinit {
        player?.pause()
    }
}
