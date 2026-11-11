import SwiftUI
import UIKit

struct SettingsView: View {

    @EnvironmentObject private var store: AppStore

    @State private var keyDraft: String = ""
    @State private var showKey: Bool = false
    @State private var downloadCount: Int = 0
    @State private var downloadBytes: Int64 = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                saveDirCard
                apiKeyCard
                updateCard
                diagnosticCard
                convenientCard
                feedbackCard
                aboutCard
                sponsorCard
                versionFooter
            }
            .padding(.horizontal, 15)
            .padding(.top, 13)
            .padding(.bottom, 30)
        }
        .background(Theme.bg)
        .onAppear {
            keyDraft = store.customApiKey
            refreshDownloads()
        }
    }

    // MARK: 文件保存

    private var saveDirCard: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionTitle(icon: "folder.fill", title: "文件保存目录设置")

                Text("iOS 采用沙盒机制，解析文件会保存到本应用的「文件」目录，可在系统「文件」App → 我的 iPhone → VideoParse → VideoParse 中查看、播放或分享。")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 10))
                    Text("已保存 \(downloadCount) 个文件 · \(Fmt.size(downloadBytes))")
                        .font(.system(size: 10.5, weight: .medium))
                }
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                HStack(spacing: 8) {
                    Button {
                        openFilesApp()
                    } label: {
                        Text("打开「文件」App")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.primary, filled: true))

                    Button {
                        clearDownloads()
                    } label: {
                        Text("清空已下载")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.coral))
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: API Key

    private var apiKeyCard: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionTitle(icon: "key.fill", title: "API Key 密钥设置", tint: Theme.indigo)

                HStack(spacing: 5) {
                    Image(systemName: store.hasBuiltInKey ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(store.hasBuiltInKey ? Theme.green : Theme.amber)
                    Text(store.hasBuiltInKey ? "内置密钥已随应用注入，可直接使用" : "未检测到内置密钥，请填写自定义 Key")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(store.hasBuiltInKey ? Theme.green : Theme.amber)
                }

                HStack(spacing: 7) {
                    Group {
                        if showKey {
                            TextField("填写你自己的 API Key", text: $keyDraft)
                        } else {
                            SecureField("填写你自己的 API Key", text: $keyDraft)
                        }
                    }
                    .font(.system(size: 11.5))
                    .foregroundColor(Theme.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(Theme.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Theme.surfaceAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack(spacing: 8) {
                    Button {
                        store.saveCustomKey(keyDraft)
                    } label: {
                        Text("保存配置")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.indigo, filled: true))

                    Button {
                        store.resetCustomKey()
                        keyDraft = ""
                    } label: {
                        Text("恢复内置")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.textSecondary))

                    Spacer(minLength: 0)

                    Text(store.hasCustomKey ? "当前：自定义" : "当前：内置")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                }

                Text("内置密钥仅用于打包分发，不在界面明文展示；如接口限额不足，可填写自己的 Key 覆盖。")
                    .font(.system(size: 9.5))
                    .foregroundColor(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: 更新

    private var updateCard: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    SectionTitle(icon: "arrow.down.circle.fill", title: "版本更新检测", tint: Theme.green)
                    Spacer(minLength: 0)
                    Text("v\(AppStore.appVersion)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.surfaceAlt)
                        .clipShape(Capsule())
                }

                Text("检查远程云端发布的最新版本修复与新增特性")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)

                switch store.updateState {
                case .checking:
                    HStack(spacing: 7) {
                        ProgressView().scaleEffect(0.7)
                        Text("正在检测远程版本更新…")
                            .font(.system(size: 10.5))
                            .foregroundColor(Theme.textSecondary)
                    }
                case .upToDate(let message):
                    Text(message)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Theme.green)
                case .failure(let message):
                    Text(message)
                        .font(.system(size: 10.5))
                        .foregroundColor(Theme.coral)
                        .fixedSize(horizontal: false, vertical: true)
                case .idle:
                    EmptyView()
                }

                HStack(spacing: 8) {
                    Button {
                        store.checkUpdateNow()
                    } label: {
                        Text("立即检查更新")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.green, filled: true))

                    if store.pendingUpdate != nil {
                        Button {
                            store.showUpdate = true
                        } label: {
                            Text("查看新版本")
                        }
                        .buttonStyle(SoftButtonStyle(tint: Theme.primary))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: 网络诊断

    private var diagnosticCard: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionTitle(icon: "waveform.path.ecg", title: "云端节点连通性诊断", tint: Theme.sky)

                Text("实时检测当前网络与云端解析服务节点之间的连接状态与响应延迟")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusText)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                Button {
                    store.testConnection()
                } label: {
                    HStack(spacing: 5) {
                        if case .checking = store.apiStatus {
                            ProgressView().scaleEffect(0.6)
                        }
                        Text("测试网络连通性")
                    }
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.sky, filled: true))
            }
        }
    }

    private var statusColor: Color {
        switch store.apiStatus {
        case .success: return Theme.green
        case .failure: return Theme.coral
        case .checking: return Theme.amber
        case .idle: return Theme.textTertiary
        }
    }

    private var statusText: String {
        switch store.apiStatus {
        case .success(let latency): return "接口连接正常，响应延迟 \(latency)ms"
        case .failure(let message): return message
        case .checking: return "正在连接并测试服务节点响应延迟…"
        case .idle: return "服务节点：云端高可用解析节点集群（未检测）"
        }
    }

    // MARK: 便捷功能

    private var convenientCard: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(icon: "switch.2", title: "便捷功能选项", tint: Theme.purple)

                Toggle(isOn: Binding(
                    get: { store.autoParseClipboard },
                    set: { store.setAutoClipboard($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("剪贴板链接自动感知")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("回到应用时自动检测剪贴板中的分享链接")
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                .tint(Theme.primary)

                Divider().background(Theme.stroke)

                Toggle(isOn: Binding(
                    get: { store.preferHighQuality },
                    set: { store.setPreferHighQuality($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("优先高清原画")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("解析结果默认选择最高清晰度直链")
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                .tint(Theme.primary)
            }
        }
    }

    // MARK: 反馈

    private var feedbackCard: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionTitle(icon: "envelope.fill", title: "意见反馈与技术联系", tint: Theme.coral)

                Text("如遇到解析异常、失效平台或功能建议，欢迎联系反馈：")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)

                Text(AppStore.feedbackEmail)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.primary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                HStack(spacing: 8) {
                    Button {
                        openMail()
                    } label: {
                        Text("打开邮件客户端反馈")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.coral, filled: true))

                    Button {
                        Clipboard.copy(AppStore.feedbackEmail)
                        store.showToast("邮箱地址已复制")
                    } label: {
                        Text("复制邮箱")
                    }
                    .buttonStyle(SoftButtonStyle(tint: Theme.textSecondary))
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: 关于

    private var aboutCard: some View {
        CardBox(padding: 14) {
            VStack(alignment: .leading, spacing: 9) {
                SectionTitle(icon: "info.circle.fill", title: "关于应用与免责声明", tint: Theme.textSecondary)

                Text("VideoParse 快析是基于网络公开 API 接口开发的第三方轻量客户端工具。开发者本人非接口服务提供方/原作者，仅提供移动端 UI 界面打包、链接格式化提取与便捷下载交互。本应用免费开放，不存储任何资源，不对第三方公开接口的稳定性与媒体版权承担法律责任。")
                    .font(.system(size: 10.5))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    store.openDisclaimer()
                } label: {
                    HStack {
                        Text("用户使用须知与免责声明")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("查看全文")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.primary)
                    }
                    .padding(10)
                    .background(Theme.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: 赞赏

    private var sponsorCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: 0xFDE68A))
                Text("赞赏与支持作者")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            Text("快析是一款免费公开的第三方打包解析工具。如果本应用对您的工作或生活有所帮助，欢迎赞赏支持开发者维护应用与持续更新！")
                .font(.system(size: 10.5))
                .foregroundColor(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    store.openSponsor()
                } label: {
                    Text("前往赞赏 (zs.69yr.cn)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x78350F))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color(hex: 0xFDE68A))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    Clipboard.copy(AppStore.sponsorURL)
                    store.showToast("赞赏链接已复制")
                } label: {
                    Text("复制链接")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())

                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(colors: [Color(hex: 0xD97706), Color(hex: 0xEF4444)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(Color.white.opacity(0.12)).frame(width: 130, height: 130).offset(x: 120, y: -55)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var versionFooter: some View {
        VStack(spacing: 3) {
            Text("VideoParse 快析 for iOS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
            Text("v\(AppStore.appVersion) (build \(AppStore.appBuild)) · SwiftUI")
                .font(.system(size: 9))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.top, 8)
    }

    // MARK: 动作

    private func refreshDownloads() {
        let files = DownloadManager.savedFiles()
        downloadCount = files.count
        var total: Int64 = 0
        for file in files {
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        downloadBytes = total
    }

    private func clearDownloads() {
        let dir = DownloadManager.downloadDir
        let files = DownloadManager.savedFiles()
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
        _ = dir
        refreshDownloads()
        store.showToast("已清空 \(files.count) 个已下载文件")
    }

    private func openFilesApp() {
        if let url = URL(string: "shareddocuments://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "file://\(DownloadManager.downloadDir.path)") {
            UIApplication.shared.open(url)
        }
    }

    private func openMail() {
        let subject = "VideoParse iOS 反馈 v\(AppStore.appVersion)"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(AppStore.feedbackEmail)?subject=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}
