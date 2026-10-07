import SwiftUI

/// 居中弹窗遮罩容器（对应 Android AlertDialog 的模态展示）
struct DialogOverlay<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            content()
                .padding(.horizontal, 24)
        }
    }
}

/// 状态卡片：空 / 加载中 / 错误（对应 Android EmptyStateCard 等）
struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 36))
                .foregroundColor(AppTheme.primary.opacity(0.7))
            Text("准备就绪")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.onSurface)
            Text("复制视频分享链接后，粘贴至上方即可极速解析无水印高清内容")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.surfaceVariant.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct LoadingStateCard: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(AppTheme.primary)
            Text("正在请求无水印高清源…")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.onSurface)
            Text("连接云端解析节点中…")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppTheme.surfaceVariant.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ErrorStateCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.error)
            Text("解析未能完成")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.error)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.error.opacity(0.85))
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    Text("重试解析")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.error)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.errorContainer.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
