import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题栏
            HStack {
                Text("设置")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // 日历尺寸
            SettingsSection(title: "日历尺寸") {
                HStack(spacing: 6) {
                    ForEach(CalendarSize.allCases, id: \.self) { size in
                        SizeButton(
                            label: size.displayName,
                            subtitle: sizeSubtitle(size),
                            isSelected: settings.calendarSize == size
                        ) {
                            settings.calendarSize = size
                        }
                    }
                }
            }

            // 位置
            SettingsSection(title: "屏幕位置") {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                    ForEach(CalendarPosition.allCases, id: \.self) { pos in
                        PositionButton(
                            label: pos.displayName,
                            isSelected: settings.calendarPosition == pos
                        ) {
                            settings.calendarPosition = pos
                        }
                    }
                }
            }

            // 开机自启动
            SettingsSection(title: "启动") {
                Toggle(isOn: $settings.launchAtLogin) {
                    Text("登录时自动启动")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .toggleStyle(.switch)
                .tint(.blue)
                .padding(.horizontal, 4)
            }

            Divider()
                .overlay(Color.white.opacity(0.15))

            // 版本信息
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                Text("桌面日历")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("v\(AppSettings.version)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(
            ZStack {
                Color.black.opacity(0.4)
                VisualEffectView(material: .menu, blendingMode: .withinWindow)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        )
    }

    private func sizeSubtitle(_ size: CalendarSize) -> String {
        let ws = size.windowSize
        return "\(Int(ws.0))×\(Int(ws.1))"
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 2)
            content()
        }
    }
}

// MARK: - Size Button

private struct SizeButton: View {
    let label: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.35) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.blue.opacity(0.6) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Position Button

private struct PositionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "circle.fill" : "circle")
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.35))
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isSelected ? Color.blue.opacity(0.35) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
