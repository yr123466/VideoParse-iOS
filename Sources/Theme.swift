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

// MARK: - 主题

enum Theme {
    static let primary = Color(hex: 0x0284C7)
    static let primaryDark = Color(hex: 0x0369A1)
    static let sky = Color(hex: 0x38BDF8)
    static let indigo = Color(hex: 0x4F46E5)
    static let amber = Color(hex: 0xD97706)
    static let coral = Color(hex: 0xEF4444)
    static let green = Color(hex: 0x10B981)
    static let purple = Color(hex: 0x8B5CF6)

    static let bg = Color.adaptive(light: 0xF8FAFC, dark: 0x0B0F19)
    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x111827)
    static let surfaceAlt = Color.adaptive(light: 0xF1F5F9, dark: 0x1F2937)
    static let stroke = Color.adaptive(light: 0xE2E8F0, dark: 0x1F2937)
    static let textPrimary = Color.adaptive(light: 0x0F172A, dark: 0xF8FAFC)
    static let textSecondary = Color.adaptive(light: 0x475569, dark: 0x94A3B8)
    static let textTertiary = Color.adaptive(light: 0x94A3B8, dark: 0x64748B)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x0284C7), Color(hex: 0x4F46E5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: 0x0EA5E9), Color(hex: 0x4F46E5)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - 通用容器

struct CardBox<Content: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SectionTitle: View {
    let icon: String
    let title: String
    var tint: Color = Theme.primary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        let info = SupportedPlatforms.info(platform)
        let color = SupportedPlatforms.color(platform)
        HStack(spacing: 4) {
            Text(info?.emoji ?? "🔗")
                .font(.system(size: 9))
            Text(info?.name ?? "其他平台")
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.primaryGradient)
                    .opacity(enabled ? 1 : 0.45)
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
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(filled ? tint : tint.opacity(0.10))
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
        .background(tint.opacity(0.08))
        .clipShape(Capsule())
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
                .overlay(
                    Capsule().stroke(selected ? Color.clear : Theme.stroke, lineWidth: 1)
                )
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
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Theme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)
        .padding(.horizontal, 24)
    }
}

/// 简易搜索框
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

/// 远程图片（带占位）
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
