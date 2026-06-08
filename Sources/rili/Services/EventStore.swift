import Foundation

@Observable
final class EventStore {
    private(set) var events: [CalendarEvent] = []

    /// 按日期索引的缓存 — 避免每次查询遍历全部事件
    private var eventsByDate: [Date: [CalendarEvent]] = [:]

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let folder = appSupport.appendingPathComponent("rili")
        fileURL = folder.appendingPathComponent("events.json")

        // 确保目录存在
        try? FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data)
        else {
            events = []
            rebuildCache()
            return
        }
        events = decoded
        rebuildCache()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Cache

    private func rebuildCache() {
        var cache: [Date: [CalendarEvent]] = [:]
        for event in events {
            let dayStart = Calendar.current.startOfDay(for: event.date)
            cache[dayStart, default: []].append(event)
        }
        // 保持按时间排序
        for key in cache.keys {
            cache[key]?.sort { ($0.time ?? Date.distantFuture) < ($1.time ?? Date.distantFuture) }
        }
        eventsByDate = cache
    }

    // MARK: - CRUD

    func add(_ event: CalendarEvent) {
        events.append(event)
        let dayStart = Calendar.current.startOfDay(for: event.date)
        eventsByDate[dayStart, default: []].append(event)
        eventsByDate[dayStart]?.sort { ($0.time ?? Date.distantFuture) < ($1.time ?? Date.distantFuture) }
        save()
    }

    func update(_ event: CalendarEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        let oldDayStart = Calendar.current.startOfDay(for: events[index].date)
        events[index] = event
        let newDayStart = Calendar.current.startOfDay(for: event.date)

        if oldDayStart == newDayStart {
            // 同一天：只更新这个事件
            if let idx = eventsByDate[newDayStart]?.firstIndex(where: { $0.id == event.id }) {
                eventsByDate[newDayStart]?[idx] = event
                eventsByDate[newDayStart]?.sort { ($0.time ?? Date.distantFuture) < ($1.time ?? Date.distantFuture) }
            }
        } else {
            // 跨天：从旧日期移除，加入新日期
            eventsByDate[oldDayStart]?.removeAll { $0.id == event.id }
            eventsByDate[newDayStart, default: []].append(event)
            eventsByDate[newDayStart]?.sort { ($0.time ?? Date.distantFuture) < ($1.time ?? Date.distantFuture) }
        }
        save()
    }

    func delete(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        let dayStart = Calendar.current.startOfDay(for: event.date)
        eventsByDate[dayStart]?.removeAll { $0.id == event.id }
        save()
    }

    /// O(1) 按日期查询 — 使用预建索引
    func events(for date: Date) -> [CalendarEvent] {
        let dayStart = Calendar.current.startOfDay(for: date)
        return eventsByDate[dayStart] ?? []
    }

    func hasEvents(for date: Date) -> Bool {
        let dayStart = Calendar.current.startOfDay(for: date)
        return eventsByDate[dayStart]?.isEmpty == false
    }
}
