import SwiftUI

// MARK: - 应用入口（对应 Android MainActivity + Application）
//
// 说明：Android 使用 ComponentActivity + setContent 承载 Compose 界面，
// iOS 使用 SwiftUI App 生命周期 + WindowGroup。

@main
struct VideoParseApp: App {

    @StateObject private var viewModel = VideoParseViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: viewModel)
                .preferredColorScheme(.light)
        }
    }
}
