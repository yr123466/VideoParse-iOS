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
                Spacer()
                content
                floatingTabBar
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
        ZStack(alignment: .center) {
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.85))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.70), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 14, y: 5)

                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.primaryGradient)
                            .frame(width: 30, height: 30)
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 1)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(tabTitle)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x0F172A))
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.system(size: 8.5))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .padding(.top, 8)
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

    @ViewBuilder
    private var floatingTabBar: some View {
        FloatingTabBar(selected: $store.selectedTab)
    }


struct FloatingTabBar: View {
    @Binding var selected: Int

    private let tabs: [(index: Int, icon: String, title: String)] = [
        (0, "bolt.fill", "解析"),
        (1, "photo.on.rectangle.angled", "素材库"),
        (2, "square.grid.2x2.fill", "平台"),
        (3, "gearshape.fill", "设置"),
    ]

    var body: some View {
        ZStack {
            // 浅色半透明胶囊背景
            Capsule()
                .fill(Color.white.opacity(0.92))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.70), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 22, y: 8)

            HStack(spacing: 6) {
                ForEach(tabs, id: \.index) { tab in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selected = tab.index
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 15, weight: .medium))
                            Text(tab.title)
                                .font(.system(size: 10.5, weight: .medium))
                        }
                        .foregroundColor(selected == tab.index ? Theme.primary : Color(hex: 0x64748B))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            ZStack {
                                if selected == tab.index {
                                    Capsule()
                                        .fill(Theme.primary.opacity(0.13))
                                        .shadow(color: Theme.primary.opacity(0.18), radius: 4, y: 2)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
        .frame(height: 54)
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }
}

}
