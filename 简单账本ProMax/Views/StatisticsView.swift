import Charts
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query(sort: \LedgerTransaction.date, order: .reverse) private var transactions: [LedgerTransaction]

    private var monthTransactions: [LedgerTransaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    private var totalExpense: Double {
        monthTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Double {
        monthTransactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
    }

    private var categoryTotals: [(String, Double)] {
        let grouped = Dictionary(grouping: monthTransactions.filter { $0.kind == .expense }, by: \.categoryName)
        return grouped
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
    }

    private var currentMonthTitle: String {
        Date.now.formatted(.dateTime.month(.wide))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(currentMonthTitle)
                            .font(.largeTitle.bold())
                        Text("¥\(totalExpense, specifier: "%.2f")")
                            .font(.system(size: 54, weight: .semibold, design: .rounded))
                        Text("收入 ¥\(totalIncome, specifier: "%.2f") · 结余 ¥\(totalIncome - totalExpense, specifier: "%.2f")")
                            .foregroundStyle(.secondary)
                    }

                    if categoryTotals.isEmpty {
                        ContentUnavailableView("暂无本月统计", systemImage: "chart.bar.xaxis", description: Text("记录支出后会显示分类排行。"))
                            .frame(height: 220)
                    } else {
                        Chart(categoryTotals, id: \.0) { item in
                            BarMark(
                                x: .value("分类", item.0),
                                y: .value("金额", item.1)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                        .frame(height: 220)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("分类排行")
                            .font(.headline)

                        if categoryTotals.isEmpty {
                            Text("本月还没有支出记录")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(categoryTotals, id: \.0) { item in
                                HStack {
                                    Text(LocalizedStringKey(item.0))
                                    Spacer()
                                    Text("¥\(item.1, specifier: "%.2f")")
                                        .foregroundStyle(.secondary)
                                }
                                Divider()
                            }
                        }
                    }
                    .padding(20)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(22)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
