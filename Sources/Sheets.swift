import SwiftUI
import UIKit

// MARK: - 免责声明

struct DisclaimerSheet: View {

    @EnvironmentObject private var store: AppStore

    private struct Clause: Identifiable {
        let id = UUID()
        let index: String
        let title: String
        let body: String
    }

    private let clauses: [Clause] = [
        Clause(index: "1", title: "软件定位与接口来源",
               body: "本软件为基于网络公开 API 接口制作的第三方轻量打包客户端工具。开发者本人非接口服务作者或版权方，仅负责移动端 UI 界面打包、链接格式化提取与便捷操作，不对第三方接口的可用性或存续性作任何保证。"),
        Clause(index: "2", title: "内容版权声明",
               body: "所有通过公开接口解析提取的视频、音频与图文内容，其完整知识产权和版权均归属原视频发布者及其对应平台所有。本应用仅提供格式化辅助，不存储任何媒体文件，亦不代表对任何内容的授权。"),
        Clause(index: "3", title: "合理学习使用",
               body: "本工具仅供个人学术研究、网络协议分析与离线学习使用。严禁将解析下载的内容用于任何形式的商业盈利、二次分发、盗版侵权或任何违反法律法规的活动。"),
        Clause(index: "4", title: "责任限制",
               body: "用户须自觉遵守相关法律法规及各平台用户守则。若因不当或违法使用所产生的任何法律纠纷、版权争议或侵权责任，均由使用者本人独立承担，与本软件打包者无关。")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .frame(width: 32, height: 32)
                    .background(Theme.primary.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text("用户使用须知与免责声明")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("欢迎使用 VideoParse 快析。在使用本应用前，请您务必仔细阅读并理解以下条款：")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(clauses) { clause in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(clause.index). \(clause.title)")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text(clause.body)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Text("点击「同意并继续」即代表您已充分阅读并完全同意上述声明与规范。")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
            }

            VStack(spacing: 8) {
                if store.disclaimerAccepted {
                    Button {
                        store.dismissDisclaimer()
                    } label: {
                        Text("我已阅读并知晓")
                    }
                    .buttonStyle(PrimaryActionStyle())
                } else {
                    Button {
                        store.acceptDisclaimer()
                    } label: {
                        Text("同意并继续")
                    }
                    .buttonStyle(PrimaryActionStyle())
                    Text("如不同意上述条款，请直接删除本应用。")
                        .font(.system(size: 9.5))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 20)
        }
        .background(Theme.bg)
        .interactiveDismissDisabled(!store.disclaimerAccepted)
    }
}

// MARK: - 版本更新

struct UpdateSheet: View {

    static let releasePage = "https://github.com/yr123466/VideoParse-iOS/releases/latest"

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let info: AppUpdateInfo?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(Theme.primaryGradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.top, 22)

                Text(info?.updateTitle ?? "发现新版本")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 7) {
                    Text("当前 v\(AppStore.appVersion)")
                    Text("→")
                    Text("最新 v\(info?.version ?? "-")")
                        .foregroundColor(Theme.primary)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)

                HStack(spacing: 6) {
                    if let size = info?.updateSize, !size.isEmpty {
                        InfoChip(icon: "internaldrive", text: size)
                    }
                    if let time = info?.updateTime, !time.isEmpty {
                        InfoChip(icon: "calendar", text: time)
                    }
                    if info?.forceUpdate == true {
                        InfoChip(icon: "exclamationmark.triangle.fill", text: "强制更新", tint: Theme.coral)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("更新内容")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(info?.updateContent ?? "暂无更新说明")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 18)
                .padding(.top, 14)
            }

            VStack(spacing: 8) {
                Button {
                    UIApplication.shared.open(URL(string: UpdateSheet.releasePage)!)
                } label: {
                    Text("前往 GitHub 下载 iOS 版")
                }
                .buttonStyle(PrimaryActionStyle())

                Text("iOS 版由 GitHub Actions 云端构建，下载最新未签名 IPA 后用 eSign / AltStore 自签安装。")
                    .font(.system(size: 9.5))
                    .foregroundColor(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                if info?.forceUpdate != true {
                    Button {
                        dismiss()
                    } label: {
                        Text("稍后再说")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 22)
        }
        .background(Theme.bg)
        .interactiveDismissDisabled(info?.forceUpdate == true)
    }
}

// MARK: - 下载进度

struct DownloadSheet: View {

    @EnvironmentObject private var downloads: DownloadManager
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var localShare: SharePayload?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: downloads.finished ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(downloads.finished ? Theme.green : Theme.primary)
                    .frame(width: 34, height: 34)
                    .background((downloads.finished ? Theme.green : Theme.primary).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(downloads.title.isEmpty ? "下载任务" : downloads.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text("保存位置：文件 App → VideoParse")
                        .font(.system(size: 9.5))
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(Theme.surfaceAlt)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)

            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceAlt).frame(height: 7)
                        Capsule()
                            .fill(downloads.finished ? AnyShapeStyle(Theme.green) : AnyShapeStyle(Theme.primaryGradient))
                            .frame(width: max(4, geo.size.width * downloads.overall), height: 7)
                    }
                }
                .frame(height: 7)

                HStack {
                    Text("\(Int(downloads.overall * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.primary)
                    Spacer()
                    Text("\(downloads.items.filter { $0.status == .done }.count) / \(downloads.items.count)")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 18)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 7) {
                    ForEach(downloads.items) { item in
                        HStack(spacing: 9) {
                            statusIcon(item.status)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)

                                if item.status == .downloading {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Theme.surfaceAlt).frame(height: 3)
                                            Capsule().fill(Theme.primary)
                                                .frame(width: max(2, geo.size.width * item.progress), height: 3)
                                        }
                                    }
                                    .frame(height: 3)
                                } else if let message = item.message, item.status == .failed {
                                    Text(message)
                                        .font(.system(size: 9))
                                        .foregroundColor(Theme.coral)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 0)

                            if item.status == .done, let url = item.savedURL {
                                HStack(spacing: 5) {
                                    Button {
                                        localShare = SharePayload(items: [url])
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(Theme.primary)
                                            .frame(width: 26, height: 26)
                                            .background(Theme.primary.opacity(0.10))
                                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Button {
                                        store.saveToAlbum(url: url, isVideo: isVideo(item))
                                    } label: {
                                        Image(systemName: "photo.badge.arrow.down")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(Theme.green)
                                            .frame(width: 26, height: 26)
                                            .background(Theme.green.opacity(0.10))
                                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                Text(item.status.label)
                                    .font(.system(size: 9))
                                    .foregroundColor(item.status == .failed ? Theme.coral : Theme.textTertiary)
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(Theme.surfaceAlt.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
            }

            HStack(spacing: 8) {
                if !downloads.finished {
                    Button {
                        downloads.cancelAll()
                    } label: {
                        Text("取消下载")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.coral))
                } else {
                    Button {
                        openFiles()
                    } label: {
                        Text("在「文件」中查看")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.primary, filled: true))
                }

                Spacer(minLength: 0)

                Button {
                    if downloads.finished { downloads.dismiss() }
                    dismiss()
                } label: {
                    Text(downloads.finished ? "完成" : "后台继续")
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.textSecondary))
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Theme.bg)
        .sheet(item: $localShare) { payload in
            ShareSheet(items: payload.items)
        }
    }

    @ViewBuilder
    private func statusIcon(_ status: DownloadStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "clock")
                .font(.system(size: 11))
                .foregroundColor(Theme.textTertiary)
        case .downloading:
            ProgressView().scaleEffect(0.6)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.coral)
        }
    }

    private func isVideo(_ item: DownloadItem) -> Bool {
        let ext = item.name.lowercased()
        return ext.hasSuffix(".mp4") || ext.hasSuffix(".mov")
    }

    private func openFiles() {
        if let url = URL(string: "shareddocuments://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "file://\(DownloadManager.downloadDir.path)") {
            UIApplication.shared.open(url)
        }
    }
}
