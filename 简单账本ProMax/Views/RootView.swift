import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            AddTransactionView()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }

            TransactionsView()
                .tabItem {
                    Label("明细", systemImage: "list.bullet.rectangle")
                }

            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }

            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
        }
        .tint(.blue)
        .task {
            SeedData.ensureDefaults(in: modelContext)
        }
    }
}
