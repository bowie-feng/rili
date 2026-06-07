import Foundation

@Observable
final class EventStore {
    private(set) var events: [CalendarEvent] = []

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
            return
        }
        events = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - CRUD

    func add(_ event: CalendarEvent) {
        events.append(event)
        save()
    }

    func update(_ event: CalendarEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
        save()
    }

    func delete(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        save()
    }

    func events(for date: Date) -> [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { ($0.time ?? Date.distantFuture) < ($1.time ?? Date.distantFuture) }
    }

    func hasEvents(for date: Date) -> Bool {
        events.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
