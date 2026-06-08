import Foundation
import Observation
import ServiceManagement

// MARK: - Enums

enum CalendarSize: String, CaseIterable, Codable {
    case medium  = "标准"
    case large   = "较大"
    case xlarge  = "最大"

    var displayName: String { rawValue }

    /// 尺寸序号 — 所有按尺寸缩放的值都用这个计算，新增 size 只需改这里
    private var sizeIndex: Int {
        switch self {
        case .medium: 0
        case .large:  1
        case .xlarge: 2
        }
    }

    /// 窗口尺寸 (宽, 高)
    var windowSize: (CGFloat, CGFloat) {
        let widths:  [CGFloat] = [430, 510, 590]
        let heights: [CGFloat] = [660, 770, 880]
        return (widths[sizeIndex], heights[sizeIndex])
    }

    /// 日期格子高度
    var cellHeight: CGFloat { [60, 72, 84][sizeIndex] }

    /// 日期数字字号
    var dayFontSize: CGFloat { [13, 15, 17][sizeIndex] }

    /// 农历字号
    var lunarFontSize: CGFloat { [8, 9, 10][sizeIndex] }

    /// 事项标题字号
    var eventFontSize: CGFloat { [8, 9, 10][sizeIndex] }

    /// 导航栏字号
    var navFontSize: CGFloat { [14, 16, 18][sizeIndex] }

    /// 周列表头字号
    var weekdayFontSize: CGFloat { [11, 12, 13][sizeIndex] }
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

    static let version = "1.1.1"

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

        // 迁移：清理 v1.0.0 遗留的 LaunchAgent plist
        Self.removeLegacyLaunchAgentPlist()

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

    /// v1.0.0 遗留的 LaunchAgent plist 路径
    private static var legacyPlistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
            .appendingPathComponent("com.rili.desktopcalendar.plist")
    }

    /// 清理 v1.0.0 通过 LaunchAgent 注册的旧登录项 plist
    private static func removeLegacyLaunchAgentPlist() {
        let url = legacyPlistURL
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

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
