import SwiftData
import SwiftUI

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LedgerTransaction.date, order: .reverse) private var transactions: [LedgerTransaction]
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(transactions) { transaction in
                    HStack(spacing: 14) {
                        Image(systemName: symbolName(for: transaction))
                            .font(.title2)
                            .foregroundStyle(color(for: transaction))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayNote(for: transaction))
                                .font(.headline)
                            Text(subtitle(for: transaction))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(prefix(for: transaction))¥\(transaction.amount, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundStyle(color(for: transaction))
                            Text(transaction.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("明细")
            .overlay {
                if transactions.isEmpty {
                    ContentUnavailableView("还没有账单", systemImage: "list.bullet.rectangle", description: Text("从“记一笔”开始记录今天。"))
                }
            }
            .alert("删除失败", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(deleteError ?? "请稍后再试。")
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(transactions[offset])
        }
        do {
            try modelContext.save()
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func symbolName(for transaction: LedgerTransaction) -> String {
        switch transaction.kind {
        case .expense: "arrow.up.circle.fill"
        case .income: "arrow.down.circle.fill"
        case .transfer: "arrow.left.arrow.right.circle.fill"
        }
    }

    private func color(for transaction: LedgerTransaction) -> Color {
        switch transaction.kind {
        case .expense: .red
        case .income: .green
        case .transfer: .blue
        }
    }

    private func prefix(for transaction: LedgerTransaction) -> String {
        switch transaction.kind {
        case .expense: "-"
        case .income: "+"
        case .transfer: ""
        }
    }

    private func subtitle(for transaction: LedgerTransaction) -> String {
        if transaction.kind == .transfer {
            return "\(localized(transaction.accountName)) → \(localized(transaction.targetAccountName ?? "未选择"))"
        }

        return "\(localized(transaction.categoryName)) · \(localized(transaction.accountName))"
    }

    private func displayNote(for transaction: LedgerTransaction) -> String {
        if transaction.note == transaction.categoryName {
            return localized(transaction.categoryName)
        }

        return transaction.note
    }

    private func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}
