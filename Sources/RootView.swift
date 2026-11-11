import SwiftUI

struct RootView: View {

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var downloads: DownloadManager
    @Environment(\.scenePhase) private var scenePhase

    private var title: String {
        switch store.selectedTab {
        case 1: return "素材库"
        case 2: return "主流平台支持"
        case 3: return "系统与接口设置"
        default: return "VideoParse 快析"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $store.selectedTab) {
                ParseView()
                    .tag(0)
                    .tabItem {
                        Label("解析", systemImage: "bolt.fill")
                    }

                LibraryView()
                    .tag(1)
                    .tabItem {
                        Label("素材库", systemImage: "photo.on.rectangle.angled")
                    }
                    .badge(store.favoriteCount)

                PlatformsView()
                    .tag(2)
                    .tabItem {
                        Label("平台", systemImage: "square.grid.2x2.fill")
                    }

                SettingsView()
                    .tag(3)
                    .tabItem {
                        Label("设置", systemImage: "gearshape.fill")
                    }
            }
            .tint(Theme.primary)
        }
        .background(Theme.bg.ignoresSafeArea())
        .overlay(alignment: .top) {
            if let toast = store.toast {
                ToastBanner(text: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(99)
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
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.primaryGradient)
                    .frame(width: 28, height: 28)
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 1)
            }

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Spacer(minLength: 0)

            Button {
                store.openSponsor()
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.coral)
                    .frame(width: 34, height: 34)
                    .background(Theme.coral.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("赞赏支持")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(
            Theme.surface
                .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 0.5)
        }
    }
}
