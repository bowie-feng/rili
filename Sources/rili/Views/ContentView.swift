import SwiftUI

struct ContentView: View {
    @State private var viewModel: CalendarViewModel
    @State private var showEventEditor = false
    @State private var editingEvent: CalendarEvent?
    let settings: AppSettings

    init(viewModel: CalendarViewModel, settings: AppSettings) {
        self._viewModel = State(initialValue: viewModel)
        self.settings = settings
    }

    var body: some View {
        VStack(spacing: 0) {
            MonthNavigationView(viewModel: viewModel, settings: settings)
                .padding(.horizontal, 14)
                .padding(.top, 18)
                .padding(.bottom, 8)

            CalendarGridView(viewModel: viewModel, settings: settings) { event in
                viewModel.selectDate(event.date)
                editingEvent = event
                showEventEditor = true
            }
            .padding(.horizontal, 10)

            // 底部：选中日期详情条（紧贴日历）
            SelectedDateBar(
                viewModel: viewModel,
                showEventEditor: $showEventEditor,
                editingEvent: $editingEvent
            )
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .background(
            Color.black.opacity(0.35)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .sheet(isPresented: $showEventEditor) {
            EventEditView(
                viewModel: viewModel,
                existingEvent: editingEvent,
                isPresented: $showEventEditor
            )
        }
        .onChange(of: showEventEditor) { _, newValue in
            if !newValue { editingEvent = nil }
        }
    }
}

// MARK: - Selected Date Bar

private struct SelectedDateBar: View {
    @Bindable var viewModel: CalendarViewModel
    @Binding var showEventEditor: Bool
    @Binding var editingEvent: CalendarEvent?

    var body: some View {
        if let date = viewModel.selectedDate {
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Text(formattedDate(date))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        let lunar = LunarCalendar.shortText(from: date)
                        if !lunar.isEmpty {
                            Text("·")
                                .foregroundColor(.white.opacity(0.6))
                            Text(lunar)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                    Spacer()
                    Button {
                        editingEvent = nil
                        showEventEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }

                let events = viewModel.eventsForSelectedDate
                if events.isEmpty {
                    Text("暂无事项，点击 + 添加")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        VStack(spacing: 3) {
                            ForEach(events) { event in
                                CompactEventRow(
                                    event: event,
                                    onTap: {
                                        editingEvent = event
                                        showEventEditor = true
                                    },
                                    onDelete: {
                                        viewModel.deleteEvent(event)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
            }
        } else {
            HStack {
                Text("点击日历格子选择日期")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "今天" }
        if cal.isDateInYesterday(date) { return "昨天" }
        if cal.isDateInTomorrow(date) { return "明天" }
        return Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "M月d日"
        return fmt
    }()

}

// MARK: - Compact Event Row

private struct CompactEventRow: View {
    let event: CalendarEvent
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.blue)
                .frame(width: 4, height: 4)

            Text(event.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            if let time = event.time {
                Text(formatTime(time))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.65))
            }

            if !event.notes.isEmpty {
                Text(event.notes)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private func formatTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt
    }()
}
