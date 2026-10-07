import SwiftUI

/// 清晰度 / 备用源选择器（对应 Android QualitySelector）
struct QualitySelector: View {
    let defaultQuality: String
    let backupList: [VideoBackupItem]
    let activeQuality: String
    let onQualitySelected: (String, String) -> Void

    var body: some View {
        if backupList.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "4k.tv")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.primary)
                    Text("可选清晰度与备用源")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.onSurface)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(backupList.enumerated()), id: \.offset) { _, item in
                            qualityChip(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func qualityChip(_ item: VideoBackupItem) -> some View {
        let label = item.displayLabel
        let isSelected = activeQuality == label
        let sizeText = (item.sizeLabel?.isEmpty == false) ? " (\(item.sizeLabel!))" : ""

        Button {
            if let url = item.url { onQualitySelected(url, label) }
        } label: {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }
                Text("\(label)\(sizeText)")
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? AppTheme.primaryContainer : AppTheme.surfaceVariant)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AppTheme.outlineVariant.opacity(0.6), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
