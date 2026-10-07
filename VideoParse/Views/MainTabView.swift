import SwiftUI
import UIKit

// MARK: - 主容器（对应 Android MainScreen）
//
// 结构：TopAppBar（含赞赏入口） + 内容区 + NavigationBar 底部导航
// 附加：首次启动免责声明弹窗、版本更新弹窗、全局 Toast 提示

struct MainTabView: View {

    @ObservedObject var viewModel: VideoParseViewModel

    @State private var selectedIndex: Int = 0

    private let tabs: [(icon: String, title: String)] = [
        ("bolt.fill", "解析"),
        ("clock", "历史"),
        ("square.grid.2x2", "平台"),
        ("gearshape", "设置")
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.declinedDisclaimer {
                DeclinedDisclaimerView(onReview: { viewModel.reopenDisclaimer() })
            } else {
                mainContent
            }

            // 免责声明弹窗（首次启动强制，或手动查看）
            if viewModel.showDisclaimerDialog {
                DialogOverlay {
                    DisclaimerDialog(
                        isFirstLaunch: !viewModel.isDisclaimerAccepted,
                        onAccept: { viewModel.acceptDisclaimer() },
                        onDecline: { viewModel.declineDisclaimer() },
                        onDismiss: { viewModel.dismissDisclaimerModal() }
                    )
                }
            }

            // 版本更新弹窗
            if viewModel.showUpdateDialog, let info = viewModel.currentUpdateInfo {
                DialogOverlay {
                    UpdateDialogView(updateInfo: info, onDismiss: { viewModel.dismissUpdateDialog() })
                }
            }

            // 全局 Toast
            if let toast = viewModel.toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 40)
                        .padding(.bottom, 96)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
    }

    // MARK: - 主内容

    private var mainContent: some View {
        VStack(spacing: 0) {
            topBar
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomBar
        }
    }

    // MARK: - 顶部标题栏

    private var topBar: some View {
        HStack(spacing: 8) {
            Text(navigationTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.onSurface)

            Spacer(minLength: 0)

            Button {
                if let url = URL(string: SettingsStore.sponsorURL) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.danger)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .overlay(alignment: .bottom) {
            Divider()
                .background(AppTheme.outlineVariant.opacity(0.4))
        }
    }

    private var navigationTitle: String {
        switch selectedIndex {
        case 0: return "VideoParse 快析"
        case 1: return "解析历史与收藏"
        case 2: return "主流平台支持"
        default: return "系统与接口设置"
        }
    }

    // MARK: - 内容区

    @ViewBuilder
    private var content: some View {
        switch selectedIndex {
        case 0:
            ParseView(viewModel: viewModel)
        case 1:
            HistoryView(viewModel: viewModel, onNavigateToParse: { selectedIndex = 0 })
        case 2:
            PlatformsView(viewModel: viewModel, onNavigateToParse: { selectedIndex = 0 })
        default:
            SettingsView(viewModel: viewModel, onOpenDisclaimer: { viewModel.openDisclaimerModal() })
        }
    }

    // MARK: - 底部导航

    private var bottomBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    selectedIndex = index
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 21))
                                .frame(width: 28, height: 26)

                            if index == 1 && viewModel.favoriteCount > 0 {
                                Text("\(viewModel.favoriteCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(AppTheme.error)
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -4)
                            }
                        }

                        Text(tab.title)
                            .font(.system(size: 11, weight: selectedIndex == index ? .semibold : .regular))
                    }
                    .foregroundColor(selectedIndex == index ? AppTheme.primary : AppTheme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .overlay(alignment: .top) {
            Divider()
                .background(AppTheme.outlineVariant.opacity(0.4))
        }
    }
}
