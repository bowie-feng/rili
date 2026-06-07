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

    static let version = "1.0.0"

    private static let defaultsKey = "rili_appSettings"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(SavedSettings.self, from: data) {
            self.calendarSize = decoded.size
            self.calendarPosition = decoded.position
            self.customOrigin = decoded.origin
        } else {
            self.calendarSize = .medium
            self.calendarPosition = .bottomRight
            self.customOrigin = nil
        }
    }

    // MARK: - Persistence

    private func save() {
        let saved = SavedSettings(
            size: calendarSize,
            position: calendarPosition,
            origin: customOrigin
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
}
