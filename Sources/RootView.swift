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
                floatingTabBar
            }

        }
        .ignoresSafeArea(edges: [.horizontal])
        .overlay {
            if store.showUpdate, let info = store.pendingUpdate {
                ZStack {
                    Color.black.opacity(0.38)
                        .ignoresSafeArea()
                        .onTapGesture { store.dismissUpdate() }

                    UpdateAlertCard(info: info)
                        .environmentObject(store)
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
                .zIndex(200)
            }
        }
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
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.primaryGradient)
                    .frame(width: 30, height: 30)
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 1)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(tabTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9.5))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // 赞赏
            Button {
                store.openSponsor()
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.coral)
                    .frame(width: 34, height: 34)
                    .background(Theme.coral.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())

            // 粘贴（仅解析页）
            if store.selectedTab == 0 {
                Button {
                    store.pasteFromClipboard()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Theme.primaryGradient)
                        .clipShape(Circle())
                        .shadow(color: Theme.primary.opacity(0.30), radius: 6, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 8)
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
        HStack(spacing: 5) {
            ForEach(tabs, id: \.index) { tab in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selected = tab.index
                    }
                } label: {
                    tabItem(icon: tab.icon, title: tab.title, isSelected: selected == tab.index)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(7)
        .padding(.horizontal, 5)
        .background {
            // iOS 26 液态玻璃：自带高光、折射与边缘光效
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.glassEffect(.regular))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.30), lineWidth: 0.8)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 22, y: 10)
        .frame(height: 64)
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    // 拆成独立子视图，避免 Xcode 26 类型检查超时
    private func tabItem(icon: String, title: String, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .symbolEffect(.bounce.byLayer, value: isSelected)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(isSelected ? Theme.primary : Color(hex: 0x8E98AB))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 2)
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .shadow(color: Theme.primary.opacity(0.18), radius: 4, y: 1)
            }
        }
        .contentShape(Rectangle())
    }
}

}
