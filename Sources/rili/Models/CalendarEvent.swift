import Foundation

struct CalendarEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var time: Date?
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        time: Date? = nil,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.notes = notes
        self.createdAt = createdAt
    }
}
