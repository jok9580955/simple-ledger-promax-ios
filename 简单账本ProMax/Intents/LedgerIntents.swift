import AppIntents
import Foundation
import SwiftData

enum IntentLedgerStore {
    static func add(kind: TransactionKind, amount: Double, note: String) throws {
        let schema = Schema([
            LedgerTransaction.self,
            LedgerCategory.self,
            LedgerAccount.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        SeedData.ensureDefaults(in: context)

        let category = kind == .income
            ? CategoryInferencer.inferIncomeCategory(from: note)
            : CategoryInferencer.inferExpenseCategory(from: note)
        let account = defaultAccountName(in: context)

        context.insert(
            LedgerTransaction(
                kind: kind,
                amount: amount,
                categoryName: category,
                accountName: account,
                note: note.isEmpty ? category : note,
                date: .now
            )
        )
        try context.save()
    }

    private static func defaultAccountName(in context: ModelContext) -> String {
        let descriptor = FetchDescriptor<LedgerAccount>(
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        let accounts = (try? context.fetch(descriptor)) ?? []
        return accounts.first(where: \.isDefault)?.name ?? accounts.first?.name ?? "微信"
    }
}

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "记录支出"
    static var description = IntentDescription("记录一笔生活支出。")
    static var openAppWhenRun = false

    @Parameter(title: "金额")
    var amount: Double

    @Parameter(title: "备注")
    var note: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            return .result(dialog: "金额需要大于0元")
        }

        try IntentLedgerStore.add(kind: .expense, amount: amount, note: note)
        return .result(dialog: "已记录\(note) \(amount)元")
    }
}

struct AddIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "记录收入"
    static var description = IntentDescription("记录一笔收入。")
    static var openAppWhenRun = false

    @Parameter(title: "金额")
    var amount: Double

    @Parameter(title: "备注")
    var note: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            return .result(dialog: "金额需要大于0元")
        }

        try IntentLedgerStore.add(kind: .income, amount: amount, note: note)
        return .result(dialog: "已记录\(note) \(amount)元")
    }
}

struct OpenAddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "打开记账"
    static var description = IntentDescription("打开简单账本的记账页面。")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "正在打开记账")
    }
}

struct LedgerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "用\(.applicationName)记录支出",
                "用\(.applicationName)记一笔支出"
            ],
            shortTitle: "记支出",
            systemImageName: "minus.circle.fill"
        )

        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "用\(.applicationName)记录收入",
                "用\(.applicationName)记一笔收入"
            ],
            shortTitle: "记收入",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: OpenAddTransactionIntent(),
            phrases: [
                "打开\(.applicationName)记账",
                "用\(.applicationName)记账"
            ],
            shortTitle: "打开记账",
            systemImageName: "square.and.pencil"
        )
    }
}
