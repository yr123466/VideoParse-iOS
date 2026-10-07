import SwiftUI

/// 网络图片加载视图（对应 Android Coil AsyncImage）
struct RemoteImage: View {
    let urlString: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: URL(string: urlString ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(icon: "photo")
            case .empty:
                ZStack {
                    AppTheme.surfaceVariant
                    ProgressView()
                }
            @unknown default:
                AppTheme.surfaceVariant
            }
        }
    }

    private func placeholder(icon: String) -> some View {
        ZStack {
            AppTheme.surfaceVariant
            Image(systemName: icon)
                .foregroundColor(AppTheme.onSurfaceVariant)
        }
    }
}
