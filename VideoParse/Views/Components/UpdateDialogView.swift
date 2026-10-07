import SwiftUI
import UIKit

/// 版本更新弹窗（对应 Android UpdateDialog）
struct UpdateDialogView: View {
    let updateInfo: AppUpdateInfo
    let onDismiss: () -> Void

    private var isForce: Bool { updateInfo.forceUpdate == true }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.primaryContainer)
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.onPrimaryContainer)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(updateInfo.updateTitle ?? "发现新版本")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.onSurface)
                    Text("版本：v\(updateInfo.version ?? "1.0.0") · \(updateInfo.updateSize ?? "10.5MB")")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                }
                Spacer()
            }
            .padding(.bottom, 14)

            if let time = updateInfo.updateTime, !time.isEmpty {
                Text("发布日期：\(time)")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.onSurfaceVariant)
                    .padding(.bottom, 8)
            }

            Text("更新内容：")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.onSurface)
                .padding(.bottom, 4)

            ScrollView {
                Text(updateInfo.updateContent ?? "修复已知问题，优化解析性能与用户体验。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.onSurfaceVariant)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(AppTheme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .frame(maxHeight: 160)

            HStack(spacing: 10) {
                if !isForce {
                    Button(action: onDismiss) {
                        Text("稍后再说")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundColor(AppTheme.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AppTheme.primary, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: openDownload) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text("立即更新")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundColor(.white)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
        }
        .padding(20)
        .frame(maxWidth: 400)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
    }

    private func openDownload() {
        let urlString = updateInfo.downloadUrl ?? "https://lkme.cc/8AD/pUbxBq3Te"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        if !isForce { onDismiss() }
    }
}
