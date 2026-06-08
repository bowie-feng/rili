import Foundation
import Observation
import ServiceManagement

// MARK: - Enums

enum CalendarSize: String, CaseIterable, Codable {
    case medium  = "标准"
    case large   = "较大"
    case xlarge  = "最大"

    var displayName: String { rawValue }

    /// 窗口尺寸 (宽, 高)
    var windowSize: (CGFloat, CGFloat) {
        switch self {
        case .medium: return (430, 660)
        case .large:  return (510, 770)
        case .xlarge: return (590, 880)
        }
    }

    /// 日期格子高度
    var cellHeight: CGFloat {
        switch self {
        case .medium: return 60
        case .large:  return 72
        case .xlarge: return 84
        }
    }

    /// 日期数字字号
    var dayFontSize: CGFloat {
        switch self {
        case .medium: return 13
        case .large:  return 15
        case .xlarge: return 17
        }
    }

    /// 农历字号
    var lunarFontSize: CGFloat {
        switch self {
        case .medium: return 8
        case .large:  return 9
        case .xlarge: return 10
        }
    }

    /// 事项标题字号
    var eventFontSize: CGFloat {
        switch self {
        case .medium: return 8
        case .large:  return 9
        case .xlarge: return 10
        }
    }

    /// 导航栏字号
    var navFontSize: CGFloat {
        switch self {
        case .medium: return 14
        case .large:  return 16
        case .xlarge: return 18
        }
    }

    /// 周列表头字号
    var weekdayFontSize: CGFloat {
        switch self {
        case .medium: return 11
        case .large:  return 12
        case .xlarge: return 13
        }
    }
}

enum CalendarPosition: String, CaseIterable, Codable {
    case topLeft     = "左上"
    case topRight    = "右上"
    case bottomLeft  = "左下"
    case bottomRight = "右下"
    case free        = "自由拖动"

    var displayName: String { rawValue }
}

// MARK: - AppSettings

@Observable
final class AppSettings: @unchecked Sendable {
    var calendarSize: CalendarSize {
        didSet { save() }
    }
    var calendarPosition: CalendarPosition {
        didSet { save() }
    }
    /// 自由模式下的窗口原点（屏幕坐标）
    var customOrigin: CGPoint? {
        didSet { save() }
    }
    /// 是否开机自启动
    var launchAtLogin: Bool {
        didSet {
            save()
            applyLaunchAtLogin(enabled: launchAtLogin)
        }
    }

    static let version = "1.0.0"

    private static let defaultsKey = "rili_appSettings"

    init() {
        let decoded: SavedSettings? = {
            guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
                  let d = try? JSONDecoder().decode(SavedSettings.self, from: data)
            else { return nil }
            return d
        }()

        self.calendarSize = decoded?.size ?? .medium
        self.calendarPosition = decoded?.position ?? .bottomRight
        self.customOrigin = decoded?.origin

        // 启动时同步实际状态 — 先检查系统状态再赋值，避免 didSet 覆盖
        let savedValue = decoded?.launchAtLogin ?? false
        let systemEnabled = SMAppService.mainApp.status == .enabled

        if savedValue && !systemEnabled {
            // 保存的是开启但系统登录项已被移除（用户可能手动删除了）
            self.launchAtLogin = false
        } else {
            self.launchAtLogin = savedValue
        }
    }

    // MARK: - Launch at Login

    private func applyLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("SMAppService error: \(error.localizedDescription)")
        }
    }

    // MARK: - Persistence

    private func save() {
        let saved = SavedSettings(
            size: calendarSize,
            position: calendarPosition,
            origin: customOrigin,
            launchAtLogin: launchAtLogin
        )
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}

/// 用于序列化的简单结构
private struct SavedSettings: Codable {
    let size: CalendarSize
    let position: CalendarPosition
    let origin: CGPoint?
    let launchAtLogin: Bool?
}
