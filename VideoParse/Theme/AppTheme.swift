import SwiftUI

// MARK: - 主题色 (对应 Android Color.kt / Theme.kt)
// Android 使用 Material3 动态取色，这里以其 Light 基准色板为统一配色。

extension Color {
    /// 由 0xAARRGGBB / 0xRRGGBB 十六进制值构建颜色
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

enum AppTheme {

    // Primary - 天空蓝
    static let primary = Color(hex: 0xFF0284C7)
    static let onPrimary = Color.white
    static let primaryContainer = Color(hex: 0xFFE0F2FE)
    static let onPrimaryContainer = Color(hex: 0xFF0369A1)

    // Secondary - 靛蓝
    static let secondary = Color(hex: 0xFF4F46E5)
    static let secondaryContainer = Color(hex: 0xFFEEF2FF)
    static let onSecondaryContainer = Color(hex: 0xFF3730A3)

    // Tertiary - 琥珀
    static let tertiary = Color(hex: 0xFFD97706)
    static let onTertiary = Color.white
    static let tertiaryContainer = Color(hex: 0xFFFEF3C7)
    static let onTertiaryContainer = Color(hex: 0xFF78350F)

    // 背景与表面
    static let background = Color(hex: 0xFFF8FAFC)
    static let surface = Color.white
    static let onSurface = Color(hex: 0xFF0F172A)
    static let surfaceVariant = Color(hex: 0xFFF1F5F9)
    static let onSurfaceVariant = Color(hex: 0xFF475569)
    static let outlineVariant = Color(hex: 0xFFCBD5E1)

    // 状态色
    static let error = Color(hex: 0xFFDC2626)
    static let errorContainer = Color(hex: 0xFFFEE2E2)
    static let success = Color(hex: 0xFF059669)
    static let successContainer = Color(hex: 0xFF10B981)
    static let danger = Color(hex: 0xFFEF4444)
}
