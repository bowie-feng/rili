import SwiftUI

struct CalendarGridView: View {
    @Bindable var viewModel: CalendarViewModel
    let settings: AppSettings

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // 周列表头
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: settings.calendarSize.weekdayFontSize, weight: .medium))
                        .foregroundColor(isWeekend(day) ? .white.opacity(0.4) : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            // 日期网格
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(Array(viewModel.daysInGrid.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCellView(
                            date: date,
                            isToday: viewModel.isToday(date),
                            isSelected: viewModel.isSelected(date),
                            events: viewModel.eventsForDate(date),
                            settings: settings
                        )
                        .frame(height: settings.calendarSize.cellHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectDate(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: settings.calendarSize.cellHeight)
                    }
                }
            }
        }
    }

    private func isWeekend(_ day: String) -> Bool {
        day == "六" || day == "日"
    }
}

// MARK: - Event Colors

/// 待办事项配色方案 — 6 种鲜艳色彩在深色背景下轮换
enum EventColor: CaseIterable {
    case blue, purple, pink, orange, green, teal

    var fill: Color {
        switch self {
        case .blue:   return Color(red: 0.30, green: 0.55, blue: 0.95)
        case .purple: return Color(red: 0.62, green: 0.45, blue: 0.95)
        case .pink:   return Color(red: 0.95, green: 0.35, blue: 0.55)
        case .orange: return Color(red: 0.95, green: 0.50, blue: 0.15)
        case .green:  return Color(red: 0.20, green: 0.80, blue: 0.35)
        case .teal:   return Color(red: 0.15, green: 0.70, blue: 0.75)
        }
    }

    /// 根据事件 ID 确定性取色，同一事件始终同一颜色
    static func forEvent(_ event: CalendarEvent) -> EventColor {
        let index = abs(event.id.hashValue) % Self.allCases.count
        return Self.allCases[index]
    }
}

// MARK: - Day Cell

struct DayCellView: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let events: [CalendarEvent]
    let settings: AppSettings

    private var day: Int { Calendar.current.component(.day, from: date) }

    var body: some View {
        let size = settings.calendarSize
        let visibleEvents = events.prefix(2)
        let overflow = events.count - visibleEvents.count

        ZStack {
            // 选中/今天背景
            RoundedRectangle(cornerRadius: 5)
                .fill(cellBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            isToday ? Color.blue.opacity(0.7) : Color.clear,
                            lineWidth: 1.5
                        )
                )

            VStack(spacing: 0) {
                // 第一行：公历日期 + 农历
                HStack(spacing: 4) {
                    Text("\(day)")
                        .font(.system(size: size.dayFontSize, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? .white : .white.opacity(0.9))

                    Text(LunarCalendar.shortText(from: date))
                        .font(.system(size: size.lunarFontSize))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    // 右上角事项计数角标
                    if !events.isEmpty {
                        Text("\(events.count)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.55))
                            )
                    }
                }
                .padding(.top, 3)
                .padding(.horizontal, 3)

                Spacer(minLength: 1)

                // 事项彩色标签
                VStack(spacing: 2) {
                    ForEach(Array(visibleEvents.enumerated()), id: \.element.id) { _, event in
                        EventTagView(
                            event: event,
                            color: EventColor.forEvent(event),
                            fontSize: size.eventFontSize
                        )
                    }

                    // 溢出提示
                    if overflow > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<min(overflow, 3), id: \.self) { i in
                                Circle()
                                    .fill(EventColor.forEvent(events[2 + i]).fill)
                                    .frame(width: 3.5, height: 3.5)
                            }
                            Text("+\(overflow)")
                                .font(.system(size: max(size.eventFontSize - 1, 7)))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .padding(.top, 1)
                    }
                }
                .padding(.horizontal, 3)
                .padding(.bottom, 3)
            }
        }
    }

    private var cellBackground: Color {
        if isSelected {
            return Color.blue.opacity(0.45)
        }
        if isToday {
            return Color.blue.opacity(0.25)
        }
        return Color.white.opacity(0.06)
    }
}

// MARK: - Event Tag

/// 单条待办事项标签 — 彩色圆角 pill
private struct EventTagView: View {
    let event: CalendarEvent
    let color: EventColor
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 3) {
            // 彩色圆点
            Circle()
                .fill(color.fill)
                .frame(width: 5, height: 5)

            // 事项标题
            Text(event.title)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.fill.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.fill.opacity(0.35), lineWidth: 0.5)
                )
        )
    }
}
