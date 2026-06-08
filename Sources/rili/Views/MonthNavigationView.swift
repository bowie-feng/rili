import SwiftUI

struct MonthNavigationView: View {
    @Bindable var viewModel: CalendarViewModel
    let settings: AppSettings

    var body: some View {
        let size = settings.calendarSize
        let navFont: CGFloat = size.navFontSize
        let chevronFont: CGFloat = navFont - 2
        let todayFont: CGFloat = navFont - 3

        HStack(spacing: 8) {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: chevronFont, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .buttonStyle(.plain)

            Text(viewModel.monthTitle)
                .font(.system(size: navFont, weight: .semibold))
                .foregroundColor(.white)

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: chevronFont, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.goToToday()
            } label: {
                Text("今天")
                    .font(.system(size: todayFont, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.35))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(height: navFont + 20)
    }
}
