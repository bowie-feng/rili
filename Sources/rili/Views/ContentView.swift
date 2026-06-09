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

            CalendarGridView(
                viewModel: viewModel,
                settings: settings,
                onEventTap: { event in
                    viewModel.selectDate(event.date)
                    editingEvent = event
                    showEventEditor = true
                },
                onDateDoubleTap: { date in
                    viewModel.selectDate(date)
                    editingEvent = nil
                    showEventEditor = true
                }
            )
            .padding(.horizontal, 10)
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
