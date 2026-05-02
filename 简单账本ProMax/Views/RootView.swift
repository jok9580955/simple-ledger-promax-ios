import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = ScreenshotMode.selectedTab

    var body: some View {
        if ScreenshotMode.isEnabled && selectedTab == 4 {
            SiriShortcutsView()
                .task {
                    SeedData.ensureScreenshotData(in: modelContext)
                }
        } else {
            TabView(selection: $selectedTab) {
            AddTransactionView()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .tag(0)

            TransactionsView()
                .tabItem {
                    Label("明细", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
            .tint(.blue)
            .task {
                if ScreenshotMode.isEnabled {
                    SeedData.ensureScreenshotData(in: modelContext)
                } else {
                    SeedData.ensureDefaults(in: modelContext)
                }
            }
        }
    }
}
