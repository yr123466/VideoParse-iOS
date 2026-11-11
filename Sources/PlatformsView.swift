import SwiftUI

struct PlatformsView: View {

    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var detail: PlatformInfo?

    private var platforms: [PlatformInfo] {
        let base = SupportedPlatforms.display
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return base }
        return base.filter { p in
            p.name.localizedCaseInsensitiveContains(query)
                || p.enName.localizedCaseInsensitiveContains(query)
                || p.id.localizedCaseInsensitiveContains(query)
                || p.formats.joined().localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                header

                SearchField(text: $query, placeholder: "搜索支持的平台（共 \(SupportedPlatforms.display.count) 个主流平台）…")

                if platforms.isEmpty {
                    CardBox(padding: 26) {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 22))
                                .foregroundColor(Theme.textTertiary)
                            Text("未找到相关平台")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(platforms) { platform in
                            PlatformCard(platform: platform) {
                                detail = platform
                            } onTest: {
                                test(platform)
                            }
                        }
                    }
                }

                Text("更多海外与腾讯系平台可在「设置 → API Key」自备密钥后按需使用，解析能力以接口实际支持为准。")
                    .font(.system(size: 9.5))
                    .foregroundColor(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 15)
            .padding(.top, 13)
            .padding(.bottom, 28)
        }
        .background(Theme.bg)
        .sheet(item: $detail) { platform in
            PlatformDetailSheet(platform: platform) {
                detail = nil
                test(platform)
            }
            .environmentObject(store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Text("全网主流媒体平台聚合支持")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
                Text("\(SupportedPlatforms.display.count)+")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white)
            }
            Text("已集成 \(SupportedPlatforms.display.count)+ 媒体与短视频平台，自动识别去水印并提取原画直链")
                .font(.system(size: 10.5))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(colors: [Color(hex: 0x4F46E5), Color(hex: 0x0EA5E9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(Color.white.opacity(0.12)).frame(width: 140, height: 140).offset(x: 130, y: -50)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Theme.indigo.opacity(0.22), radius: 12, y: 6)
    }

    private func test(_ platform: PlatformInfo) {
        if platform.sampleUrl.contains("xxxx") {
            store.showToast("该平台示例链接为占位符，请粘贴真实分享链接")
            return
        }
        store.inputText = platform.sampleUrl
        store.selectedTab = 0
        store.parse(platform.sampleUrl)
    }
}

// MARK: - 平台卡片

struct PlatformCard: View {
    let platform: PlatformInfo
    let onOpen: () -> Void
    let onTest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(platform.emoji)
                    .font(.system(size: 17))
                    .frame(width: 34, height: 34)
                    .background(platform.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(platform.name)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(platform.enName)
                        .font(.system(size: 8.5))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            Text(platform.formats.prefix(3).joined(separator: " · "))
                .font(.system(size: 9))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Button(action: onTest) {
                    Text("测试")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(platform.color)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(platform.color.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())

                Spacer(minLength: 0)

                Button(action: onOpen) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 7, y: 3)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }
}

// MARK: - 平台详情

struct PlatformDetailSheet: View {

    let platform: PlatformInfo
    let onTest: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 11) {
                    Text(platform.emoji)
                        .font(.system(size: 26))
                        .frame(width: 52, height: 52)
                        .background(platform.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(platform.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text(platform.enName)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }

                CardBox(padding: 14) {
                    VStack(alignment: .leading, spacing: 9) {
                        SectionTitle(icon: "sparkles", title: "支持的格式", tint: platform.color)
                        HStack(spacing: 6) {
                            ForEach(platform.formats, id: \.self) { format in
                                Text(format)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(platform.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(platform.color.opacity(0.10))
                                    .clipShape(Capsule())
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }

                CardBox(padding: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(icon: "lightbulb", title: "使用提示", tint: Theme.amber)
                        Text(platform.tips)
                            .font(.system(size: 11.5))
                            .foregroundColor(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("示例：\(platform.sampleUrl)")
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.textTertiary)
                            .lineLimit(3)
                            .padding(9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surfaceAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onTest()
                    }
                } label: {
                    Text("用示例链接测试解析")
                }
                .buttonStyle(PrimaryActionStyle())

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .background(Theme.bg)
    }
}
