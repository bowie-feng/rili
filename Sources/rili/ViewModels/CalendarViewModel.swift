import Foundation
import Observation

@Observable
final class CalendarViewModel {
    let eventStore: EventStore

    var currentMonth: Date
    var selectedDate: Date?

    init(eventStore: EventStore = EventStore()) {
        self.eventStore = eventStore
        self.currentMonth = CalendarViewModel.startOfMonth(for: Date())
        self.selectedDate = nil
    }

    // MARK: - Computed

    var events: [CalendarEvent] {
        eventStore.events
    }

    var eventsForSelectedDate: [CalendarEvent] {
        guard let date = selectedDate else { return [] }
        return eventStore.events(for: date)
    }

    var monthTitle: String {
        Self.monthTitleFormatter.string(from: currentMonth)
    }

    private static let monthTitleFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年 M月"
        return fmt
    }()

    /// 当前月份的天数网格（6 行 × 7 列）
    var daysInGrid: [Date?] {
        let cal = Calendar.current
        guard let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)),
              let range = cal.range(of: .day, in: .month, for: firstDay)
        else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstDay) - 1 // 0=周日

        var grid: [Date?] = []

        // 填充前面的空白
        for _ in 0..<firstWeekday {
            grid.append(nil)
        }

        // 填充月份中的每一天
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstDay) {
                grid.append(date)
            }
        }

        // 补齐到 42 格
        while grid.count < 42 {
            grid.append(nil)
        }

        return grid
    }

    // MARK: - Navigation

    func goToNextMonth() {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = next
    }

    func goToPreviousMonth() {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = prev
    }

    func goToToday() {
        currentMonth = CalendarViewModel.startOfMonth(for: Date())
        selectedDate = Date()
    }

    // MARK: - Event Actions

    func selectDate(_ date: Date?) {
        selectedDate = date
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selected)
    }

    func hasEvents(on date: Date) -> Bool {
        eventStore.hasEvents(for: date)
    }

    func eventsForDate(_ date: Date) -> [CalendarEvent] {
        eventStore.events(for: date)
    }

    func addEvent(title: String, date: Date, time: Date?, notes: String) {
        let event = CalendarEvent(title: title, date: date, time: time, notes: notes)
        eventStore.add(event)
    }

    func updateEvent(_ event: CalendarEvent) {
        eventStore.update(event)
    }

    func deleteEvent(_ event: CalendarEvent) {
        eventStore.delete(event)
    }

    // MARK: - Helpers

    private static func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }
}
