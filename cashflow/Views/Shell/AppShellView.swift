import SwiftUI

struct AppShellView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeDashboardView(selectedTab: $selectedTab)
            case .calendar:
                CalendarOverviewView()
            case .reports:
                ReportsHubView()
            case .goals:
                GoalsHomeView()
            case .settings:
                SettingsHomeView()
            case .books:
                BooksHomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                AppTabBar(selectedTab: $selectedTab)
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
