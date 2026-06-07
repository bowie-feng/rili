import SwiftUI

struct EventEditView: View {
    @Bindable var viewModel: CalendarViewModel
    let existingEvent: CalendarEvent?
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var hasTime = false
    @State private var time = Date()
    @State private var notes = ""

    private var editingDate: Date {
        viewModel.selectedDate ?? Date()
    }

    init(viewModel: CalendarViewModel, existingEvent: CalendarEvent?, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.existingEvent = existingEvent
        self._isPresented = isPresented

        if let event = existingEvent {
            self._title = State(initialValue: event.title)
            self._hasTime = State(initialValue: event.time != nil)
            self._time = State(initialValue: event.time ?? Date())
            self._notes = State(initialValue: event.notes)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text(existingEvent == nil ? "添加事项" : "编辑事项")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // 日期显示
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(formatDate(editingDate))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // 标题输入
            VStack(alignment: .leading, spacing: 4) {
                Text("标题")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("事项标题", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // 时间开关
            Toggle(isOn: $hasTime) {
                Text("设置时间")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.checkbox)

            if hasTime {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            // 备注输入
            VStack(alignment: .leading, spacing: 4) {
                Text("备注")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("备注信息", text: $notes)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // 操作按钮
            HStack {
                if existingEvent != nil {
                    Button {
                        viewModel.deleteEvent(existingEvent!)
                        isPresented = false
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Text("取消")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)

                Button {
                    save()
                } label: {
                    Text(existingEvent == nil ? "添加" : "保存")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.blue.opacity(0.3) : Color.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        if let existing = existingEvent {
            var updated = existing
            updated.title = trimmedTitle
            updated.time = hasTime ? time : nil
            updated.notes = notes
            viewModel.updateEvent(updated)
        } else {
            viewModel.addEvent(
                title: trimmedTitle,
                date: editingDate,
                time: hasTime ? time : nil,
                notes: notes
            )
        }
        isPresented = false
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = cal.isDateInToday(date) ? "'今天' M月d日" : "M月d日 EEEE"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: date)
    }
}
