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
            // 底栏改为悬浮覆盖层：内容从其下方穿过，玻璃才能透出背后的滚动内容
            .overlay(alignment: .bottom) {
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
        // 页面左右轻扫也能切 Tab（与底栏拖动呼应）
        .simultaneousGesture(
            DragGesture(minimumDistance: 28)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) * 1.6 else { return }
                    let delta = value.translation.width < 0 ? 1 : -1
                    let next = min(max(store.selectedTab + delta, 0), 3)
                    guard next != store.selectedTab else { return }
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                        store.selectedTab = next
                    }
                }
        )
    }

    @ViewBuilder
    private var floatingTabBar: some View {
        FloatingTabBar(selected: $store.selectedTab)
    }
}


struct FloatingTabBar: View {
    @Binding var selected: Int

    private static let tabCount = 4
    private static let tabs: [TabSpec] = [
        TabSpec(index: 0, icon: "bolt.fill", title: "解析"),
        TabSpec(index: 1, icon: "photo.on.rectangle.angled", title: "素材库"),
        TabSpec(index: 2, icon: "square.grid.2x2.fill", title: "平台"),
        TabSpec(index: 3, icon: "gearshape.fill", title: "设置"),
    ]

    /// 手指拖动产生的额外位移（点），叠加在选中项位置上
    @State private var dragX: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let slot = geo.size.width / CGFloat(Self.tabCount)
            let baseX = (CGFloat(selected) + 0.5) * slot

            // 拖动时按位移推算出「当前指向的项」，胶囊跟着手指走
            let targetIndex = index(at: baseX + dragX, slot: slot)
            let shownX = isDragging
                ? clampX(baseX + dragX, slot: slot)
                : baseX

            ZStack {
                pillLayer(slot: slot, x: shownX, stretch: stretchFactor(slot: slot))
                itemsLayer(slot: slot, activeIndex: isDragging ? targetIndex : selected)
            }
            .frame(height: 50)
            .contentShape(Rectangle())
            .gesture(dragGesture(slot: slot))
        }
        .padding(7)
        .padding(.horizontal, 5)
        .glassDock(cornerRadius: 26)
        .frame(height: 64)
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    // MARK: 图层

    private func pillLayer(slot: CGFloat, x: CGFloat, stretch: CGFloat) -> some View {
        Capsule()
            .fill(Color.white.opacity(0.16))
            .glassEffect(.clear, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            .frame(width: max(38, slot - 10 + stretch), height: 42)
            .position(x: x, y: 25)
            .animation(isDragging ? nil : .spring(response: 0.34, dampingFraction: 0.74), value: selected)
    }

    private func itemsLayer(slot: CGFloat, activeIndex: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Self.tabs) { tab in
                TabBarButton(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: activeIndex == tab.index
                ) {
                    guard selected != tab.index else { return }
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
                        selected = tab.index
                    }
                }
                .frame(width: slot)
            }
        }
    }

    // MARK: 手势

    private func dragGesture(slot: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                isDragging = true
                dragX = value.translation.width
            }
            .onEnded { value in
                let from = (CGFloat(selected) + 0.5) * slot
                let predicted = value.predictedEndTranslation.width
                // 用预测位移做甩动判定，轻扫也能切页
                let landing = index(at: from + predicted * 0.8, slot: slot)
                isDragging = false
                dragX = 0
                if landing != selected {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
                        selected = landing
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }

    // MARK: 计算

    private func index(at x: CGFloat, slot: CGFloat) -> Int {
        let raw = Int(x / max(slot, 1))
        return min(max(raw, 0), Self.tabCount - 1)
    }

    private func clampX(_ x: CGFloat, slot: CGFloat) -> CGFloat {
        let half = slot / 2
        return min(max(x, half), slot * CGFloat(Self.tabCount) - half)
    }

    /// 离最近槽位越远，胶囊横向拉伸越多，产生液体形变
    private func stretchFactor(slot: CGFloat) -> CGFloat {
        guard isDragging else { return 0 }
        let x = (CGFloat(selected) + 0.5) * slot + dragX
        let nearest = (CGFloat(index(at: x, slot: slot)) + 0.5) * slot
        return min(abs(x - nearest) * 0.35, slot * 0.42)
    }
}

struct TabSpec: Identifiable {
    let index: Int
    let icon: String
    let title: String
    var id: Int { index }
}

private struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var label: some View {
        VStack(spacing: 4) {
            iconView
            Text(title)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(isSelected ? Theme.primary : Color(hex: 0x8E98AB))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .symbolEffect(.bounce.byLayer, value: isSelected)
    }
}

// MARK: - 液态玻璃 Dock 背景

private extension View {
    func glassDock(cornerRadius: CGFloat) -> some View {
        self
            // .clear 为 iOS 26 的「透明玻璃」变体：透出背后内容，仅做轻微磨砂与高光
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.42), lineWidth: 0.7)
            }
            .shadow(color: Color.black.opacity(0.22), radius: 20, y: 8)
    }
}
