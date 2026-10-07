import SwiftUI
import UIKit

// MARK: - 解析页（对应 Android ParseScreen）

struct ParseView: View {
    @ObservedObject var viewModel: VideoParseViewModel

    private let samples: [(name: String, url: String)] = [
        ("抖音", "0.00 复制打开抖音，看看【D2024yr的图文作品】这是一条测试贴，如此你看到了说明成功了  https://v.douyin.com/UlLYRaUfLOY/ Pkp:/ 08/05 :0pm c@N.jc "),
        ("豆包", "https://www.doubao.com/thread/xb2J8bOUM4ePcAJph"),
        ("B站", "【Impactor 自签全流程教学 ios自签教学已测ios26.1可用其他版本需自测-哔哩哔哩】 https://b23.tv/Hsrdls0"),
        ("快手", "https://v.kuaishou.com/xxxx"),
        ("小红书", "http://xhslink.com/xxxx")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let detected = viewModel.detectedClipboardUrl, !detected.isEmpty {
                    clipboardBanner(url: detected)
                }

                inputCard

                stateArea
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: 剪贴板检测横幅

    @ViewBuilder
    private func clipboardBanner(url: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.onSecondaryContainer)

            VStack(alignment: .leading, spacing: 2) {
                Text("检测到剪贴板中含有视频链接")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.onSecondaryContainer)
                Text(url)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.onSecondaryContainer.opacity(0.8))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button {
                viewModel.pasteText(url)
                viewModel.parse(urlOverride: url)
            } label: {
                Text("一键解析")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.dismissClipboardBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.onSecondaryContainer)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.secondaryContainer)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: 输入卡片

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primary)
                Text("全网短视频无水印解析")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.onSurface)
                Spacer()
                Text("第三方公开接口")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.primary)
            }

            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("粘贴抖音/快手/小红书/B站等分享口令或网址…")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.onSurfaceVariant.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }

                TextEditor(text: $viewModel.inputText)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.onSurface)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(4)
            }
            .padding(6)
            .background(AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.outlineVariant, lineWidth: 1)
            )

            if !viewModel.inputText.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        viewModel.clearInput()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("清空")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Button {
                    pasteFromClipboard()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 15))
                        Text("粘贴")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .foregroundColor(AppTheme.onSurfaceVariant)
                    .background(AppTheme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.parse()
                } label: {
                    HStack(spacing: 6) {
                        if isParsing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 15))
                        }
                        Text(isParsing ? "解析中…" : "立即解析")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .foregroundColor(.white)
                    .background(isParsing ? AppTheme.primary.opacity(0.6) : AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isParsing)
                .layoutPriority(1)
                .frame(maxWidth: .infinity)
            }

            // 快速测试示例
            VStack(alignment: .leading, spacing: 6) {
                Text("快速测试示例：")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.onSurfaceVariant)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(samples, id: \.name) { sample in
                            Button {
                                viewModel.fillSampleUrl(sample.url)
                            } label: {
                                Text(sample.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.surfaceVariant.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var isParsing: Bool {
        if case .loading = viewModel.parseState { return true }
        return false
    }

    private func pasteFromClipboard() {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            viewModel.pasteText(text)
        }
    }

    // MARK: 状态区域

    @ViewBuilder
    private var stateArea: some View {
        switch viewModel.parseState {
        case .idle:
            EmptyStateCard()
        case .loading:
            LoadingStateCard()
        case .error(let message):
            ErrorStateCard(message: message, onRetry: { viewModel.parse() })
        case .success(let response, let activeVideoUrl, let activeQuality):
            if let data = response.data {
                ParseResultCard(
                    data: data,
                    platform: response.platform ?? "全网",
                    activeVideoUrl: activeVideoUrl,
                    activeQuality: activeQuality,
                    viewModel: viewModel
                )
            }
        }
    }
}
