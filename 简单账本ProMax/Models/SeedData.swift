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
}
