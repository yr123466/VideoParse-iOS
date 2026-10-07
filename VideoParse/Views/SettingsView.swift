import SwiftUI
import UIKit

// MARK: - 系统与接口设置页（对应 Android SettingsScreen）

struct SettingsView: View {
    @ObservedObject var viewModel: VideoParseViewModel
    let onOpenDisclaimer: () -> Void

    @State private var editingKey = ""
    @State private var isKeyVisible = false
    @State private var showFolderPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                saveDirectoryCard
                apiKeyCard
                updateCard
                feedbackCard
                apiStatusCard
                preferencesCard
                aboutCard
                sponsorCard
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear { editingKey = viewModel.customApiKey }
        .onChange(of: viewModel.customApiKey) { newValue in
            editingKey = newValue
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker { url in
                viewModel.updateSaveDir(url: url)
                viewModel.showToast("已成功设置默认保存目录: \(url.lastPathComponent)")
            }
        }
    }

    // MARK: 1. 保存目录

    private var saveDirectoryCard: some View {
        settingsCard {
            cardTitle(icon: "folder", text: "文件保存目录设置")

            Text("支持自定义视频与图片的默认保存位置，方便分类整理与相册同步")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .padding(.top, 6)

            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前默认目录：")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                    Text(viewModel.customSaveDirName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.onSurface)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.surfaceVariant.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.top, 10)

            HStack(spacing: 10) {
                primaryButton(title: "自选指定目录", icon: "folder.badge.plus") {
                    showFolderPicker = true
                }

                if viewModel.customSaveDirURL != nil {
                    outlineButton(title: "恢复默认", icon: "arrow.uturn.backward") {
                        viewModel.resetSaveDir()
                        viewModel.showToast("已恢复系统默认下载目录")
                    }
                }
            }
            .padding(.top, 12)
        }
    }

    // MARK: 2. API Key

    private var apiKeyCard: some View {
        settingsCard {
            HStack(spacing: 8) {
                cardTitle(icon: "key", text: "API Key 密钥设置")
                Spacer()
                Text(viewModel.hasCustomApiKey ? "自定义密钥" : "内置密钥生效中")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(viewModel.hasCustomApiKey ? AppTheme.onPrimaryContainer : AppTheme.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(viewModel.hasCustomApiKey ? AppTheme.primaryContainer : AppTheme.successContainer.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            Text(viewModel.hasCustomApiKey
                 ? "当前正在使用您配置的自定义 API Key。如需换回内置免费密钥，可点击下方“恢复内置”。"
                 : "内置 API Key 已加密保护并默认启用。若您拥有自己的独立密钥，可在下方填入覆盖。")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .padding(.top, 6)

            HStack(spacing: 8) {
                if isKeyVisible {
                    TextField(viewModel.hasCustomApiKey ? "请输入自定义 API Key" : "内置密钥已生效（输入自定义 Key 可替换）",
                              text: $editingKey)
                        .font(.system(size: 13))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField(viewModel.hasCustomApiKey ? "请输入自定义 API Key" : "内置密钥已生效（输入自定义 Key 可替换）",
                                text: $editingKey)
                        .font(.system(size: 13))
                }

                Button {
                    isKeyVisible.toggle()
                } label: {
                    Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                        .foregroundColor(AppTheme.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.outlineVariant, lineWidth: 1)
            )
            .padding(.top, 12)

            HStack(spacing: 10) {
                primaryButton(title: "保存配置", icon: nil) {
                    if !editingKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.saveCustomApiKey(editingKey)
                        viewModel.showToast("自定义 API Key 已保存")
                    } else {
                        viewModel.resetToBuiltInKey()
                        viewModel.showToast("已恢复使用内置密钥")
                    }
                }

                if viewModel.hasCustomApiKey {
                    outlineButton(title: "恢复内置", icon: "arrow.uturn.backward") {
                        viewModel.resetToBuiltInKey()
                        editingKey = ""
                        viewModel.showToast("已恢复使用内置密钥")
                    }
                }
            }
            .padding(.top, 12)
        }
    }

    // MARK: 3. 版本更新

    private var updateCard: some View {
        settingsCard {
            HStack(spacing: 8) {
                cardTitle(icon: "arrow.triangle.2.circlepath", text: "版本更新检测")
                Spacer()
                Text("当前版本 v\(viewModel.currentVersion)")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.onSurfaceVariant)
            }

            Text("检查远程云端发布的最新版本修复与新增特性")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .padding(.top, 6)

            updateStatusView
                .padding(.top, 10)

            Button {
                viewModel.checkAppUpdate(manual: true)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14))
                    Text("立即检查更新")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch viewModel.updateUiState {
        case .checking:
            statusRow(icon: nil, color: AppTheme.onSurface, text: "正在检测远程版本更新…", showSpinner: true)
        case .upToDate(let message):
            statusRow(icon: "checkmark.circle.fill", color: AppTheme.success, text: message)
        case .error(let message):
            statusRow(icon: "exclamationmark.triangle", color: AppTheme.error, text: message)
        default:
            EmptyView()
        }
    }

    // MARK: 4. 意见反馈

    private var feedbackCard: some View {
        settingsCard {
            cardTitle(icon: "envelope", text: "意见反馈与技术联系")

            Text("如遇到解析异常、失效平台或功能建议，欢迎联系反馈：")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .padding(.top, 6)

            HStack(spacing: 8) {
                Text(viewModel.feedbackEmail)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                Spacer()
                Button {
                    UIPasteboard.general.string = viewModel.feedbackEmail
                    viewModel.showToast("反馈邮箱 已复制到剪贴板")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.surfaceVariant.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.top, 10)

            Button {
                openMail()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 14))
                    Text("打开邮件客户端反馈")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    private func openMail() {
        let subject = "【VideoParse 快析】用户问题与反馈"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(viewModel.feedbackEmail)?subject=\(encodedSubject)") {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    UIPasteboard.general.string = viewModel.feedbackEmail
                    viewModel.showToast("已复制反馈邮箱到剪贴板")
                }
            }
        }
    }

    // MARK: 5. 接口连通性

    private var apiStatusCard: some View {
        settingsCard {
            cardTitle(icon: "speedometer", text: "云端节点连通性诊断")

            Text("实时检测当前网络与云端解析服务节点之间的连接状态与响应延迟")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .padding(.top, 6)

            Group {
                switch viewModel.apiStatusState {
                case .idle:
                    statusRow(icon: nil, color: AppTheme.onSurfaceVariant,
                              text: "服务节点: 云端高可用解析节点集群 (状态正常)")
                case .checking:
                    statusRow(icon: nil, color: AppTheme.onSurface,
                              text: "正在连接并测试服务节点响应延迟…", showSpinner: true)
                case .success(_, let message):
                    statusRow(icon: "checkmark.circle.fill", color: AppTheme.primary, text: message)
                case .error(let message):
                    statusRow(icon: "exclamationmark.triangle", color: AppTheme.error, text: message)
                }
            }
            .padding(.top, 12)

            Button {
                viewModel.testApiConnection()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 14))
                    Text("测试网络连通性")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
    }

    // MARK: 6. 便捷选项

    private var preferencesCard: some View {
        settingsCard {
            cardTitle(icon: "slider.horizontal.3", text: "便捷功能选项")

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("剪贴板链接自动感知")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.onSurface)
                    Text("切换至本应用时自动识别剪贴板短视频口令并提示解析")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.onSurfaceVariant)
                }
                Spacer(minLength: 0)
                Toggle("", isOn: Binding(
                    get: { viewModel.autoParseClipboard },
                    set: { viewModel.toggleAutoParseClipboard($0) }
                ))
                .labelsHidden()
                .tint(AppTheme.primary)
            }
            .padding(.top, 10)
        }
    }

    // MARK: 7. 关于与免责声明

    private var aboutCard: some View {
        settingsCard {
            cardTitle(icon: "info.circle", text: "关于应用与免责声明")

            Text("VideoParse 快析是基于网络公开 API 接口开发的第三方轻量客户端工具。开发者本人非接口服务提供方/原作者，仅提供移动端 UI 界面打包、链接格式化提取与便捷下载交互。本应用免费开放，不存储任何资源，不对第三方公开接口的稳定性与媒体版权承担法律责任。")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onSurfaceVariant)
                .lineSpacing(5)
                .padding(.top, 10)

            Divider()
                .background(AppTheme.outlineVariant.opacity(0.5))
                .padding(.top, 12)

            Button(action: onOpenDisclaimer) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.primary)
                    Text("用户使用须知与免责声明")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.onSurface)
                    Spacer()
                    Text("查看全文")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: 8. 赞赏

    private var sponsorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.tertiary)
                Text("赞赏与支持作者")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.onTertiaryContainer)
            }

            Text("快析是一款免费公开的第三方打包解析工具。如果本应用对您的工作或生活有所帮助，欢迎赞赏支持开发者维护应用与持续更新！")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.onTertiaryContainer.opacity(0.9))
                .lineSpacing(4)
                .padding(.top, 6)

            HStack(spacing: 10) {
                Button {
                    if let url = URL(string: SettingsStore.sponsorURL) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13))
                        Text("前往赞赏 (zs.69yr.cn)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.onTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppTheme.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    UIPasteboard.general.string = SettingsStore.sponsorURL
                    viewModel.showToast("赞赏地址 已复制到剪贴板")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13))
                        Text("复制链接")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(AppTheme.onTertiaryContainer)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.tertiary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.tertiaryContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - 通用组件

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    private func cardTitle(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.primary)
            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.onSurface)
        }
    }

    @ViewBuilder
    private func statusRow(icon: String?, color: Color, text: String, showSpinner: Bool = false) -> some View {
        HStack(spacing: 6) {
            if showSpinner {
                ProgressView()
                    .scaleEffect(0.7)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func primaryButton(title: String, icon: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func outlineButton(title: String, icon: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.primary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
