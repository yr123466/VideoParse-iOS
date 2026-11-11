import SwiftUI
import AVFAudio

@main
@MainActor
struct VideoParseApp: App {

    @StateObject private var store = AppStore()
    @StateObject private var downloads = DownloadManager.shared

    init() {
        // 允许静音键开启时也能播放声音（与 Android 端行为一致）
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("audio session error: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(downloads)
                .tint(Theme.primary)
        }
    }
}
