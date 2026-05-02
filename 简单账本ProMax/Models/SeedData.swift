import Foundation
import SwiftData

enum SeedData {
    static func ensureDefaults(in context: ModelContext) {
        let categoryDescriptor = FetchDescriptor<LedgerCategory>()
        let accountDescriptor = FetchDescriptor<LedgerAccount>()

        let existingCategories = (try? context.fetch(categoryDescriptor)) ?? []
        let existingCategoryKeys = Set(existingCategories.map { "\($0.kindRawValue)|\($0.name)" })

        for (index, item) in LedgerDefaults.expenseCategories.enumerated() {
            if !existingCategoryKeys.contains("\(TransactionKind.expense.rawValue)|\(item.0)") {
                context.insert(LedgerCategory(name: item.0, symbolName: item.1, kind: .expense, sortIndex: index))
            }
        }

        for (index, item) in LedgerDefaults.incomeCategories.enumerated() {
            if !existingCategoryKeys.contains("\(TransactionKind.income.rawValue)|\(item.0)") {
                context.insert(LedgerCategory(name: item.0, symbolName: item.1, kind: .income, sortIndex: index))
            }
        }

        let existingAccounts = (try? context.fetch(accountDescriptor)) ?? []
        let existingAccountNames = Set(existingAccounts.map(\.name))

        for (index, item) in LedgerDefaults.accounts.enumerated() {
            if !existingAccountNames.contains(item.0) {
                context.insert(LedgerAccount(name: item.0, symbolName: item.1, isDefault: index == 0, sortIndex: index))
            }
        }

        if !existingAccounts.isEmpty && !existingAccounts.contains(where: \.isDefault) {
            existingAccounts.sorted { $0.sortIndex < $1.sortIndex }.first?.isDefault = true
        }

        try? context.save()
    }

    static func ensureScreenshotData(in context: ModelContext) {
        ensureDefaults(in: context)

        let descriptor = FetchDescriptor<LedgerTransaction>()
        let existingTransactions = (try? context.fetch(descriptor)) ?? []
        guard existingTransactions.isEmpty else {
            return
        }

        let calendar = Calendar.current
        let now = Date()

        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        let samples: [LedgerTransaction] = [
            LedgerTransaction(kind: .expense, amount: 36, categoryName: "餐饮", accountName: "微信", note: "餐饮", date: date(daysAgo: 0)),
            LedgerTransaction(kind: .expense, amount: 18, categoryName: "交通", accountName: "支付宝", note: "交通", date: date(daysAgo: 1)),
            LedgerTransaction(kind: .expense, amount: 128, categoryName: "购物", accountName: "银行卡", note: "购物", date: date(daysAgo: 2)),
            LedgerTransaction(kind: .expense, amount: 29, categoryName: "娱乐", accountName: "微信", note: "娱乐", date: date(daysAgo: 3)),
            LedgerTransaction(kind: .expense, amount: 2680, categoryName: "住房", accountName: "银行卡", note: "住房", date: date(daysAgo: 5)),
            LedgerTransaction(kind: .income, amount: 12000, categoryName: "工资", accountName: "银行卡", note: "工资", date: date(daysAgo: 6)),
            LedgerTransaction(kind: .income, amount: 860, categoryName: "兼职", accountName: "微信", note: "兼职", date: date(daysAgo: 8)),
            LedgerTransaction(kind: .transfer, amount: 1000, categoryName: "转账", accountName: "微信", targetAccountName: "银行卡", note: "转账", date: date(daysAgo: 9))
        ]

        samples.forEach(context.insert)
        try? context.save()
    }
}

enum ScreenshotMode {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT")

    static var selectedTab: Int {
        UserDefaults.standard.integer(forKey: "ScreenshotMode")
    }
}
