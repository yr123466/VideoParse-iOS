import SwiftUI

/// 用户使用须知与免责声明（对应 Android DisclaimerDialog）
struct DisclaimerDialog: View {
    let isFirstLaunch: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("用户使用须知与免责声明")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(AppTheme.onSurface)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("欢迎使用 VideoParse 快析。在使用本应用前，请您务必仔细阅读并理解以下条款：")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.onSurface)
                        .lineSpacing(4)

                    disclaimerItem(
                        index: "1",
                        title: "软件定位与接口来源",
                        body: "本软件为基于网络公开 API 接口制作的第三方轻量打包客户端工具。开发者本人非接口服务作者或版权方，仅负责移动端 UI 界面打包、链接格式化提取与便捷操作，不对第三方接口的可用性或存续性作任何保证。"
                    )
                    disclaimerItem(
                        index: "2",
                        title: "内容版权声明",
                        body: "所有通过公开接口解析提取的视频、音频与图文内容，其完整知识产权和版权均归属原视频发布者及其对应平台所有。本应用仅提供格式化辅助，不存储任何媒体文件，亦不代表对任何内容的授权。"
                    )
                    disclaimerItem(
                        index: "3",
                        title: "合理学习使用",
                        body: "本工具仅供个人学术研究、网络协议分析与离线学习使用。严禁将解析下载的内容用于任何形式的商业盈利、二次分发、盗版侵权或任何违反法律法规的活动。"
                    )
                    disclaimerItem(
                        index: "4",
                        title: "责任限制",
                        body: "用户须自觉遵守相关法律法规及各平台用户守则。若因不当或违法使用所产生的任何法律纠纷、版权争议或侵权责任，均由使用者本人独立承担，与本软件打包者无关。"
                    )

                    Text("点击“同意并继续”即代表您已充分阅读并完全同意上述声明与规范。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 340)

            HStack(spacing: 10) {
                if isFirstLaunch {
                    Button(action: onDecline) {
                        Text("不同意并退出")
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
                } else {
                    Button(action: onDismiss) {
                        Text("关闭")
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

                Button(action: onAccept) {
                    Text(isFirstLaunch ? "同意并继续" : "我已阅读并知晓")
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

    @ViewBuilder
    private func disclaimerItem(index: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(index). \(title)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.onSurface)
            Text(body)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .lineSpacing(3)
        }
        .padding(.bottom, 4)
    }
}

/// 拒绝免责声明后的占位页（对应 Android finishAffinity 退出）
struct DeclinedDisclaimerView: View {
    let onReview: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.primary)
            Text("需同意用户须知后方可使用")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.onSurface)
            Text("VideoParse 快析为第三方公开接口打包工具，请阅读并同意免责声明后再继续使用。")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onReview) {
                Text("重新阅读条款")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 46)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}
