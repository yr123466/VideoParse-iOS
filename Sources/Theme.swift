import SwiftUI
import UIKit

// MARK: - 颜色工具

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - 主题色板（沿用安卓端 0x0284C7 / 0x4F46E5 蓝紫）

enum Theme {
    static let primary = Color(hex: 0x0284C7)
    static let primaryDark = Color(hex: 0x0369A1)
    static let sky = Color(hex: 0x38BDF8)
    static let indigo = Color(hex: 0x4F46E5)
    static let amber = Color(hex: 0xD97706)
    static let coral = Color(hex: 0xEF4444)
    static let green = Color(hex: 0x10B981)
    static let purple = Color(hex: 0x8B5CF6)
    static let gray = Color(hex: 0x64748B)

    static let bg = Color.adaptive(light: 0xF8FAFC, dark: 0x0B0F19)
    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x111827)
    static let surfaceAlt = Color.adaptive(light: 0xF1F5F9, dark: 0x1F2937)
    static let stroke = Color.adaptive(light: 0xE2E8F0, dark: 0x1F2937)
    static let textPrimary = Color.adaptive(light: 0x0F172A, dark: 0xF8FAFC)
    static let textSecondary = Color.adaptive(light: 0x475569, dark: 0x94A3B8)
    static let textTertiary = Color.adaptive(light: 0x94A3B8, dark: 0x64748B)

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: 0x0EA5E9), Color(hex: 0x4F46E5)],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x0284C7), Color(hex: 0x4F46E5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let coralGradient = LinearGradient(
        colors: [Color(hex: 0xF59E0B), Color(hex: 0xEF4444)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// iOS 26 风格：毛玻璃装饰卡（正文区所有容器统一使用）
    static let glassCardMaterial = AnyShapeStyle(
        Color.adaptive(light: 0xFFFFFF, dark: 0x0F172A).opacity(0.55)
    )

    /// 背景浮动色块：为主内容区增添深度，不遮挡文字
    static let meshBackground = AnyView(
        ZStack {
            Color.adaptive(light: 0xF8FAFC, dark: 0x0B0F19)
            meshBlob(x: 0.70, y: -0.25, size: 620, color: Color(hex: 0x0EA5E9).opacity(0.22), blur: 140)
            meshBlob(x: -0.15, y: 0.85, size: 560, color: Color(hex: 0x4F46E5).opacity(0.18), blur: 140)
            meshBlob(x: 0.85, y: 0.55, size: 500, color: Color(hex: 0xD97706).opacity(0.14), blur: 120)
        }
        .ignoresSafeArea()
    )

    @ViewBuilder
    static func meshBlob(x: CGFloat, y: CGFloat, size: CGFloat, color: Color, blur: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(x: UIScreen.main.bounds.width * x, y: UIScreen.main.bounds.height * y)
            .blur(radius: blur)
    }
}

// MARK: - 通用容器：毛玻璃卡

struct CardBox<Content: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = 24
    var fill: AnyShapeStyle? = nil
    var strokeWidth: CGFloat = 1
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AnyShapeStyle(
                    fill ?? AnyShapeStyle(ZStack {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(Theme.glassCardMaterial)
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    })
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: strokeWidth)
            )
    }
}

struct SectionTitle: View {
    let icon: String
    let title: String
    var tint: Color = Theme.primary

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 26, height: 26)
            }
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 平台徽标

struct PlatformBadge: View {
    let platform: String

    var body: some View {
        let color = SupportedPlatforms.color(platform)
        HStack(spacing: 4) {
            Text(SupportedPlatforms.emoji(platform))
                .font(.system(size: 9))
            Text(SupportedPlatforms.name(platform))
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(
            Capsule().fill(color.opacity(0.14))
            .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
        )
    }
}

// MARK: - 按钮样式

struct PrimaryActionStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(Theme.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.20)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(enabled ? 0.25 : 0.10), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.primary
    var filled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(filled ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surfaceAlt))
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - 小标签

struct InfoChip: View {
    let icon: String?
    let text: String
    var tint: Color = Theme.textSecondary

    var body: some View {
        HStack(spacing: 3) {
            if let icon = icon {
                Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            }
            Text(text).font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(tint.opacity(0.12)).overlay(Capsule().stroke(tint.opacity(0.40), lineWidth: 1))
        )
    }
}

struct SelectableChip: View {
    let text: String
    let selected: Bool
    var tint: Color = Theme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: selected ? .bold : .medium))
                .foregroundColor(selected ? .white : Theme.textSecondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surfaceAlt))
                )
                .overlay(Capsule().stroke(selected ? Color.clear : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 提示条

struct ToastBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.green)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Theme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.14), radius: 16, y: 7)
        .padding(.horizontal, 24)
    }
}

// MARK: - 搜索框

struct SearchField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
            TextField(placeholder, text: $text)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

// MARK: - 远程图片

struct RemoteImage: View {
    let url: String
    var contentMode: ContentMode = .fill

    var body: some View {
        if let u = URL(string: url), !url.isEmpty {
            AsyncImage(url: u) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                case .empty:
                    ZStack {
                        Theme.surfaceAlt
                        ProgressView().scaleEffect(0.7)
                    }
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Theme.surfaceAlt
            Image(systemName: "photo")
                .font(.system(size: 22))
                .foregroundColor(Theme.textTertiary)
        }
    }
}

// MARK: - 屏幕容器：毛玻璃背景 + 标题行

/// 屏幕根容器：在内容下层放置浮动色块，顶部紧贴屏幕边缘（浸出顶栏）
struct ScreenRoot<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Theme.meshBackground
        content
    }
}

/// 屏幕标题：大号标题 + 副说明，右侧可放图标按钮
struct ScreenHeader<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ZStack(alignment: .topLeading) {
            leading
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
}

struct ScreenHeaderLeading<Content: View>: View {
    var title: String
    var subtitle: String
    var tint: Color = Theme.primary
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                if let content = content as? Never { EmptyView() }
                content
            }
            Text(subtitle)
                .font(.system(size: 10.5))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// 方便使用的简化标题
struct SimpleHeader: View {
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(subtitle)
                .font(.system(size: 10.5))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
}

// MARK: - 浮动标签栏（iOS 26 风格胶囊）

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
            Capsule()
                .fill(Theme.surface)
                .overlay(Capsule().stroke(Theme.stroke.opacity(0.55), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)

            HStack(spacing: 6) {
                ForEach(tabs, id: \.index) { tab in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selected = tab.index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(selected == tab.index ? Theme.primary : Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selected == tab.index {
                                    Capsule()
                                        .fill(Theme.primaryGradient)
                                        .shadow(color: Theme.primary.opacity(0.35), radius: 6, y: 3)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 6)
        }
        .frame(height: 50)
        .padding(.horizontal, 32)
        .padding(.bottom, 14)
    }
}
