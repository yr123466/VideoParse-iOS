import SwiftUI
import UIKit

// MARK: - 操作按钮区（对应 Android ActionButtonsRow）
// 下载 / 复制直链 / 自选目录保存 / 复制音乐 / 复制封面 / 复制文案 / 分享

@MainActor
struct ActionButtonsView: View {
    let data: ParseData
    let activeVideoUrl: String
    @ObservedObject var viewModel: VideoParseViewModel

    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    private var effectiveVideo: String {
        if !activeVideoUrl.isEmpty { return activeVideoUrl }
        if let url = data.url, !url.isEmpty { return url }
        return data.liveVideoURL ?? ""
    }

    private var allImages: [String] { data.allImages }
    private var isVideo: Bool { !effectiveVideo.isEmpty }

    private var defaultFileName: String {
        let raw = data.title ?? "media"
        let limited = String(raw.prefix(30))
        let sanitized = limited.replacingOccurrences(
            of: "[^a-zA-Z0-9\\u4e00-\\u9fa5_]",
            with: "_",
            options: .regularExpression
        )
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        return "\(sanitized)_\(timestamp).\(isVideo ? "mp4" : "jpg")"
    }

    var body: some View {
        VStack(spacing: 10) {
            // 主要操作：下载 + 复制直链
            HStack(spacing: 10) {
                Button {
                    handleDownload()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                        Text(isVideo ? "下载无水印视频" : "保存全部高清图片")
                            .lineLimit(1)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(.white)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    copyDirectLink()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("复制无水印直链").lineLimit(1)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(AppTheme.primary)
                    .background(AppTheme.primaryContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            // 次级工具按钮
            HStack(spacing: 8) {
                utilityButton(icon: "folder.badge.gearshape", title: "自选目录保存…") {
                    handleSaveAs()
                }
                if let musicUrl = data.music?.url, !musicUrl.isEmpty {
                    utilityButton(icon: "music.note", title: "复制音乐链接") {
                        copyToClipboard(label: "背景音乐直链", text: musicUrl)
                    }
                }
            }

            HStack(spacing: 8) {
                if let cover = data.cover, !cover.isEmpty {
                    utilityButton(icon: "photo", title: "复制高清封面") {
                        copyToClipboard(label: "封面链接", text: cover)
                    }
                }
                let desc = data.desc ?? data.title
                if let desc = desc, !desc.isEmpty {
                    utilityButton(icon: "text.alignleft", title: "复制视频文案") {
                        copyToClipboard(label: "视频文案", text: desc)
                    }
                }
            }

            HStack(spacing: 8) {
                utilityButton(icon: "square.and.arrow.up", title: "分享") {
                    handleShare()
                }
                Spacer(minLength: 0)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(items: shareItems)
        }
    }

    @ViewBuilder
    private func utilityButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
            }
            .foregroundColor(AppTheme.onSurfaceVariant)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.outlineVariant, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 动作实现

    private func handleDownload() {
        guard isVideo || !allImages.isEmpty else {
            viewModel.showToast("未找到可下载的媒体直链")
            return
        }

        if SettingsStore.shared.resolveCustomSaveDir() != nil {
            viewModel.showToast("正在下载至设置的指定目录…")
            Task {
                do {
                    if isVideo {
                        let dirName = try await MediaSaver.shared.saveToCustomDirectory(
                            urlString: effectiveVideo,
                            filename: defaultFileName,
                            settings: SettingsStore.shared
                        )
                        viewModel.showToast("已成功保存至自定义目录：\(dirName)")
                    } else {
                        for (index, imageUrl) in allImages.enumerated() {
                            _ = try await MediaSaver.shared.saveToCustomDirectory(
                                urlString: imageUrl,
                                filename: "image_\(index + 1)_\(Int(Date().timeIntervalSince1970)).jpg",
                                settings: SettingsStore.shared
                            )
                        }
                        viewModel.showToast("已保存全部 \(allImages.count) 张图片至自定义目录")
                    }
                } catch {
                    await downloadToPhotos()
                }
            }
        } else {
            Task { await downloadToPhotos() }
        }
    }

    private func downloadToPhotos() async {
        do {
            if isVideo {
                viewModel.showToast("正在下载无水印视频…")
                try await MediaSaver.shared.saveVideoToPhotos(urlString: effectiveVideo)
                viewModel.showToast("视频已保存到相册")
            } else {
                viewModel.showToast("正在保存高清图片…")
                for imageUrl in allImages {
                    try await MediaSaver.shared.saveImageToPhotos(urlString: imageUrl)
                }
                viewModel.showToast("已保存全部 \(allImages.count) 张图片到相册")
            }
        } catch {
            viewModel.showToast(error.localizedDescription)
        }
    }

    private func handleSaveAs() {
        let downloadUrl = isVideo ? effectiveVideo : (allImages.first ?? "")
        guard !downloadUrl.isEmpty else {
            viewModel.showToast("未找到可保存的媒体直链")
            return
        }
        viewModel.showToast("正在准备文件…")
        Task {
            do {
                let local = try await MediaSaver.shared.downloadToTemporary(
                    urlString: downloadUrl,
                    suggestedName: defaultFileName
                )
                shareItems = [local]
                showShareSheet = true
            } catch {
                viewModel.showToast("保存失败: \(error.localizedDescription)")
            }
        }
    }

    private func handleShare() {
        let shareUrl = isVideo ? effectiveVideo : (allImages.first ?? "")
        let text = "\(data.title ?? "")\n无水印直链: \(shareUrl)"
        shareItems = [text]
        showShareSheet = true
    }

    private func copyDirectLink() {
        let directUrl = isVideo ? effectiveVideo : (allImages.first ?? "")
        guard !directUrl.isEmpty else {
            viewModel.showToast("直链为空")
            return
        }
        copyToClipboard(label: "无水印直链", text: directUrl)
    }

    private func copyToClipboard(label: String, text: String) {
        UIPasteboard.general.string = text
        viewModel.showToast("\(label) 已复制到剪贴板")
    }
}
