import SwiftUI
import UIKit

struct RootView: View {

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var downloads: DownloadManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.meshBackground

            VStack(spacing: 0) {
                topBar

                content
            }

            // 右上角：赞赏按钮（浸出顶部，悬浮）
            VStack {
                HStack {
                    Spacer()
                    Button {
                        store.openSponsor()
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.coral)
                            .frame(width: 40, height: 40)
                            .background(Theme.coral.opacity(0.16))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(color: Theme.coral.opacity(0.30), radius: 8, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 42)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .ignoresSafeArea(edges: [.horizontal])
        .overlay(alignment: .top) {
            if let toast = store.toast {
                ToastBanner(text: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .padding(.horizontal, 6)
            }
        }
        .sheet(isPresented: $store.showDisclaimer) {
            DisclaimerSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.showUpdate) {
            UpdateSheet(info: store.pendingUpdate)
                .environmentObject(store)
        }
        .sheet(isPresented: $downloads.isVisible) {
            DownloadSheet()
                .environmentObject(downloads)
                .environmentObject(store)
        }
        .sheet(item: $downloads.sharePayload) { payload in
            ShareSheet(items: payload.items)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.checkClipboard()
            }
        }
        .onAppear {
            store.checkClipboard()
        }
    }

    private var topBar: some View {
        ZStack(alignment: .leading) {
            ZStack {
                Capsule()
                    .fill(Theme.surface)
                    .overlay(Capsule().stroke(Theme.stroke.opacity(0.50), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.14), radius: 14, y: 5)

                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.primaryGradient)
                            .frame(width: 32, height: 32)
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 1)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(tabTitle)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.textTertiary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // 右侧悬浮快捷：粘贴（仅在解析页有意义）
            HStack {
                Spacer()
                if store.selectedTab == 0 {
                    Button {
                        store.pasteFromClipboard()
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Theme.primaryGradient)
                            .clipShape(Circle())
                            .shadow(color: Theme.primary.opacity(0.45), radius: 8, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.trailing, 24)
            .padding(.top, 12)
        }
    }

    private var tabTitle: String {
        switch store.selectedTab {
        case 1: return "素材库"
        case 2: return "主流平台支持"
        case 3: return "系统与接口设置"
        default: return "VideoParse 快析"
        }
    }

    private var subtitle: String {
        switch store.selectedTab {
        case 0: return "全网短视频无水印解析"
        case 1: return "\(store.history.count) 条素材 · \(store.favoriteCount) 收藏"
        case 2: return "\(SupportedPlatforms.display.count)+ 主流平台聚合支持"
        case 3: return "接口设置与云端节点诊断"
        default: return ""
        }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            ParseView()
                .opacity(store.selectedTab == 0 ? 1 : 0)
                .allowsHitTesting(store.selectedTab == 0)
            LibraryView()
                .opacity(store.selectedTab == 1 ? 1 : 0)
                .allowsHitTesting(store.selectedTab == 1)
            PlatformsView()
                .opacity(store.selectedTab == 2 ? 1 : 0)
                .allowsHitTesting(store.selectedTab == 2)
            SettingsView()
                .opacity(store.selectedTab == 3 ? 1 : 0)
                .allowsHitTesting(store.selectedTab == 3)
        }
        .animation(nil, value: store.selectedTab)
    }

    private var floatingTabBar: some View {
        FloatingTabBar(selected: $store.selectedTab)
    }

}
