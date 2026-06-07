import Foundation

/// 农历日期信息
struct LunarDate {
    let month: Int       // 1-12
    let day: Int         // 1-30
    let isLeapMonth: Bool
    let monthName: String    // 正月、二月...腊月
    let dayName: String      // 初一、初二...三十
    let festival: String?    // 节日名称（如果是节日）
}

/// 农历工具类，封装 Foundation 的 Chinese calendar
enum LunarCalendar {

    private static let chineseCalendar = Calendar(identifier: .chinese)
    private static let gregorianCalendar = Calendar.current

    /// 中国传统节日映射 (month, day) -> 节日名
    private static let festivals: [String: String] = [
        "1-1":  "春节",
        "1-15": "元宵节",
        "5-5":  "端午节",
        "7-7":  "七夕",
        "7-15": "中元节",
        "8-15": "中秋节",
        "9-9":  "重阳节",
        "12-8": "腊八节",
    ]

    // MARK: - Public

    /// 将公历日期转换为农历日期
    static func lunarDate(from date: Date) -> LunarDate {
        let comps = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        let isLeap = comps.isLeapMonth ?? false

        return LunarDate(
            month: month,
            day: day,
            isLeapMonth: isLeap,
            monthName: monthName(month, isLeap: isLeap),
            dayName: dayName(day),
            festival: festivalName(month: month, day: day, isLeap: isLeap, date: date)
        )
    }

    /// 获取简洁的农历显示文本（如 "初一"、"十五"）
    static func shortText(from date: Date) -> String {
        let ld = lunarDate(from: date)
        // 节日优先
        if let f = ld.festival {
            return f
        }
        // 初一显示月份
        if ld.day == 1 {
            return ld.monthName
        }
        return ld.dayName
    }

    // MARK: - Private Helpers

    private static func monthName(_ month: Int, isLeap: Bool) -> String {
        let prefix = isLeap ? "闰" : ""
        let names = ["", "正月", "二月", "三月", "四月", "五月", "六月",
                     "七月", "八月", "九月", "十月", "十一月", "腊月"]
        guard month >= 1 && month <= 12 else { return "" }
        return prefix + names[month]
    }

    private static func dayName(_ day: Int) -> String {
        let names = [
            "", "初一", "初二", "初三", "初四", "初五",
            "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五",
            "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五",
            "廿六", "廿七", "廿八", "廿九", "三十"
        ]
        guard day >= 1 && day <= 30 else { return "" }
        return names[day]
    }

    private static func festivalName(month: Int, day: Int, isLeap: Bool, date: Date) -> String? {
        // 闰月不过节
        if isLeap { return nil }

        // 除夕特殊处理：腊月最后一天
        if month == 12 {
            if let lastDay = lastDayOfLunarMonth(from: date), day == lastDay {
                return "除夕"
            }
        }

        return festivals["\(month)-\(day)"]
    }

    /// 判断某日期所在农历月有多少天
    private static func lastDayOfLunarMonth(from date: Date) -> Int? {
        // 取当月最后一天：找到下个月初一，往前推一天
        var dc = DateComponents()
        dc.month = 1
        dc.day = 1
        dc.isLeapMonth = false
        guard let nextMonthFirst = chineseCalendar.nextDate(
            after: date, matching: dc, matchingPolicy: .nextTime
        ) else { return nil }

        guard let lastDayDate = chineseCalendar.date(byAdding: .day, value: -1, to: nextMonthFirst) else {
            return nil
        }
        return chineseCalendar.component(.day, from: lastDayDate)
    }
}
