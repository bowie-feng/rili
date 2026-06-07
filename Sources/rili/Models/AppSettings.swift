import Foundation
import Observation

// MARK: - Enums

enum CalendarSize: String, CaseIterable, Codable {
    case medium  = "标准"
    case large   = "较大"
    case xlarge  = "最大"

    var displayName: String { rawValue }

    /// 窗口尺寸 (宽, 高)
    var windowSize: (CGFloat, CGFloat) {
        switch self {
        case .medium: return (430, 620)
        case .large:  return (510, 720)
        case .xlarge: return (590, 820)
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
            Self.applyLaunchAtLogin(enabled: oldValue)
        }
    }

    static let version = "1.0.0"

    private static let defaultsKey = "rili_appSettings"

    /// LaunchAgent plist 路径
    private static var launchAgentPlistURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        return dir.appendingPathComponent("com.rili.desktopcalendar.plist")
    }

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
        self.launchAtLogin = decoded?.launchAtLogin ?? false

        // 启动时同步实际状态（用户可能手动删除了 plist）
        if self.launchAtLogin {
            let exists = FileManager.default.fileExists(
                atPath: Self.launchAgentPlistURL.path
            )
            if !exists {
                self.launchAtLogin = false
                save()
            }
        }
    }

    // MARK: - Launch at Login

    static func applyLaunchAtLogin(enabled: Bool) {
        let dir = launchAgentPlistURL.deletingLastPathComponent()

        if enabled {
            // 确保 LaunchAgents 目录存在
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )

            let plist: [String: Any] = [
                "Label": "com.rili.desktopcalendar",
                "Program": Bundle.main.bundlePath + "/Contents/MacOS/rili",
                "RunAtLoad": true,
                "KeepAlive": false,
            ]
            _ = (plist as NSDictionary).write(
                to: launchAgentPlistURL,
                atomically: true
            )
        } else {
            try? FileManager.default.removeItem(at: launchAgentPlistURL)
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
    let launchAtLogin: Bool
}
