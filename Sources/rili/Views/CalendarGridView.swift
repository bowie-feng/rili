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
                }
                .padding(.top, 4)

                Spacer(minLength: 1)

                // 事项标题（最多显示 2 条）
                VStack(spacing: 1) {
                    ForEach(events.prefix(2)) { event in
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.blue.opacity(0.85))
                                .frame(width: 3, height: 3)
                            Text(event.title)
                                .font(.system(size: size.eventFontSize))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
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
