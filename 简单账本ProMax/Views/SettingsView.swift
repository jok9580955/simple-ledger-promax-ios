import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("monthlyBudget") private var monthlyBudget = 0.0
    @AppStorage("privacyLockEnabled") private var privacyLockEnabled = false
    @Query(sort: \LedgerTransaction.date, order: .reverse) private var transactions: [LedgerTransaction]
    @Query(sort: \LedgerCategory.sortIndex) private var categories: [LedgerCategory]
    @Query(sort: \LedgerAccount.sortIndex) private var accounts: [LedgerAccount]

    @State private var exportedFile: URL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SiriShortcutsView()
                    } label: {
                        Label("Siri 与快捷指令", systemImage: "waveform")
                    }

                    NavigationLink {
                        BudgetSettingsView()
                    } label: {
                        Label("预算", systemImage: "gauge.with.dots.needle.33percent")
                    }

                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("分类管理", systemImage: "square.grid.2x2.fill")
                    }

                    NavigationLink {
                        AccountManagementView()
                    } label: {
                        Label("账户管理", systemImage: "creditcard.fill")
                    }
                }

                Section {
                    Toggle(isOn: $privacyLockEnabled) {
                        Label("隐私锁", systemImage: "faceid")
                    }

                    Button {
                        exportedFile = makeBackupFile()
                    } label: {
                        Label("数据备份", systemImage: "icloud.fill")
                    }

                    Button {
                        exportedFile = makeCSVFile()
                    } label: {
                        Label("导出 CSV", systemImage: "square.and.arrow.up")
                    }
                }

                if let exportedFile {
                    Section {
                        ShareLink(item: exportedFile) {
                            Label("分享导出文件", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section("概览") {
                    LabeledContent("账单", value: transactions.count.formatted())
                    LabeledContent("分类", value: categories.count.formatted())
                    LabeledContent("账户", value: accounts.count.formatted())
                    LabeledContent("本月预算", value: monthlyBudgetSummary)
                }
            }
            .navigationTitle("我的")
            .alert("导出失败", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(exportError ?? "请稍后再试。")
            }
        }
    }

    private func makeCSVFile() -> URL? {
        let rows = transactions.map { transaction in
            [
                transaction.date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false)),
                transaction.kindRawValue,
                String(format: "%.2f", transaction.amount),
                transaction.categoryName,
                transaction.accountName,
                transaction.targetAccountName ?? "",
                transaction.note
            ].map(csvEscape).joined(separator: ",")
        }

        let content = (["date,type,amount,category,account,targetAccount,note"] + rows).joined(separator: "\n")
        return writeExportFile(content: content, fileName: "simple-ledger-export.csv")
    }

    private var monthlyBudgetSummary: String {
        monthlyBudget > 0 ? "¥\(String(format: "%.2f", monthlyBudget))" : "未设置"
    }

    private func makeBackupFile() -> URL? {
        let items = transactions.map { transaction in
            BackupTransaction(
                id: transaction.id,
                kind: transaction.kindRawValue,
                amount: transaction.amount,
                categoryName: transaction.categoryName,
                accountName: transaction.accountName,
                targetAccountName: transaction.targetAccountName,
                note: transaction.note,
                date: transaction.date,
                createdAt: transaction.createdAt,
                updatedAt: transaction.updatedAt
            )
        }

        do {
            let data = try JSONEncoder.exportEncoder.encode(items)
            let content = String(decoding: data, as: UTF8.self)
            return writeExportFile(content: content, fileName: "simple-ledger-backup.json")
        } catch {
            exportError = error.localizedDescription
            return nil
        }
    }

    private func writeExportFile(content: String, fileName: String) -> URL? {
        do {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SimpleLedgerExports", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(fileName)
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            exportError = error.localizedDescription
            return nil
        }
    }

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

private struct BackupTransaction: Codable {
    var id: UUID
    var kind: String
    var amount: Double
    var categoryName: String
    var accountName: String
    var targetAccountName: String?
    var note: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date
}

private extension JSONEncoder {
    static var exportEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

struct BudgetSettingsView: View {
    @AppStorage("monthlyBudget") private var monthlyBudget = 0.0
    @State private var budgetText = ""

    var body: some View {
        Form {
            Section {
                TextField("每月预算", text: $budgetText)
                    .keyboardType(.decimalPad)
                Button("保存预算") {
                    monthlyBudget = parsedBudget
                    budgetText = monthlyBudget > 0 ? String(format: "%.2f", monthlyBudget) : ""
                }
                .disabled(parsedBudget < 0)

                if monthlyBudget > 0 {
                    Button("清除预算", role: .destructive) {
                        monthlyBudget = 0
                        budgetText = ""
                    }
                }
            } footer: {
                Text("预算会用于首页进度和剩余额度提示，只保存在本机。")
            }
        }
        .navigationTitle("预算")
        .onAppear {
            budgetText = monthlyBudget > 0 ? String(format: "%.2f", monthlyBudget) : ""
        }
    }

    private var parsedBudget: Double {
        if budgetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return 0
        }

        return Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? -1
    }
}

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LedgerCategory.sortIndex) private var categories: [LedgerCategory]
    @State private var newName = ""
    @State private var newKind: TransactionKind = .expense

    var body: some View {
        Form {
            Section("新增分类") {
                Picker("类型", selection: $newKind) {
                    Text("支出").tag(TransactionKind.expense)
                    Text("收入").tag(TransactionKind.income)
                }
                TextField("分类名称", text: $newName)
                Button("添加") {
                    addCategory()
                }
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("支出") {
                categoryRows(for: .expense)
            }

            Section("收入") {
                categoryRows(for: .income)
            }
        }
        .navigationTitle("分类管理")
    }

    @ViewBuilder
    private func categoryRows(for kind: TransactionKind) -> some View {
        ForEach(categories.filter { $0.kind == kind }) { category in
            Label(LocalizedStringKey(category.name), systemImage: category.symbolName)
        }
        .onDelete { offsets in
            deleteCategories(kind: kind, offsets: offsets)
        }
    }

    private func addCategory() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        let nextIndex = ((categories.filter { $0.kind == newKind }.map(\.sortIndex).max() ?? -1) + 1)
        modelContext.insert(LedgerCategory(name: name, symbolName: newKind == .income ? "plus.circle.fill" : "tag.fill", kind: newKind, sortIndex: nextIndex))
        try? modelContext.save()
        newName = ""
    }

    private func deleteCategories(kind: TransactionKind, offsets: IndexSet) {
        let items = categories.filter { $0.kind == kind }
        for offset in offsets {
            modelContext.delete(items[offset])
        }
        try? modelContext.save()
    }
}

struct AccountManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LedgerAccount.sortIndex) private var accounts: [LedgerAccount]
    @State private var newName = ""

    var body: some View {
        Form {
            Section("新增账户") {
                TextField("账户名称", text: $newName)
                Button("添加") {
                    addAccount()
                }
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("账户") {
                ForEach(accounts) { account in
                    HStack {
                        Label(LocalizedStringKey(account.name), systemImage: account.symbolName)
                        Spacer()
                        if account.isDefault {
                            Text("默认")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("设为默认") {
                                setDefault(account)
                            }
                            .font(.caption)
                        }
                    }
                }
                .onDelete(perform: deleteAccounts)
            }
        }
        .navigationTitle("账户管理")
    }

    private func addAccount() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        let nextIndex = ((accounts.map(\.sortIndex).max() ?? -1) + 1)
        modelContext.insert(LedgerAccount(name: name, symbolName: "creditcard.fill", isDefault: accounts.isEmpty, sortIndex: nextIndex))
        try? modelContext.save()
        newName = ""
    }

    private func setDefault(_ account: LedgerAccount) {
        accounts.forEach { $0.isDefault = $0.id == account.id }
        try? modelContext.save()
    }

    private func deleteAccounts(at offsets: IndexSet) {
        guard accounts.count > 1 else {
            return
        }

        for offset in offsets {
            if accounts.count - offsets.count <= 0 {
                break
            }
            modelContext.delete(accounts[offset])
        }

        let remaining = accounts.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)
        if !remaining.contains(where: \.isDefault) {
            remaining.sorted { $0.sortIndex < $1.sortIndex }.first?.isDefault = true
        }
        try? modelContext.save()
    }
}

struct SiriShortcutsView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("用一句话完成记账。")
                        .font(.title2.bold())
                    Text("Siri 会根据备注自动匹配分类，金额和账单会直接保存到本地。")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("你可以这样说") {
                Text("“用简单账本记录午餐 28 元”")
                Text("“记录打车 36 元”")
                Text("“记录工资 8000 元”")
                Text("“打开简单账本记账”")
            }
        }
        .navigationTitle("Siri")
    }
}
