import SwiftData
import SwiftUI

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("monthlyBudget") private var monthlyBudget = 0.0
    @Query(sort: \LedgerCategory.sortIndex) private var categories: [LedgerCategory]
    @Query(sort: \LedgerAccount.sortIndex) private var accounts: [LedgerAccount]

    @State private var kind: TransactionKind = .expense
    @State private var amountText = ""
    @State private var selectedCategoryName = "餐饮"
    @State private var selectedAccountName = "微信"
    @State private var selectedTargetAccountName = "银行卡"
    @State private var note = ""
    @State private var date = Date()
    @State private var showSaved = false
    @State private var saveError: String?

    private var filteredCategories: [LedgerCategory] {
        categories.filter { $0.kind == kind }
    }

    @Query(sort: \LedgerTransaction.date, order: .reverse) private var transactionsInCurrentMonth: [LedgerTransaction]

    private var currentMonthTransactions: [LedgerTransaction] {
        transactionsInCurrentMonth.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    private var monthlyExpense: Double {
        currentMonthTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyIncome: Double {
        currentMonthTransactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyBalance: Double {
        monthlyIncome - monthlyExpense
    }

    private var monthlyRemainingBudget: Double? {
        guard monthlyBudget > 0 else {
            return nil
        }

        return monthlyBudget - monthlyExpense
    }

    private var amount: Double {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    monthlyHeader
                    amountInput
                    typePicker
                    categoryGrid
                    details
                    saveButton
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今天花了多少？")
            .navigationBarTitleDisplayMode(.large)
            .alert("已记录", isPresented: $showSaved) {
                Button("好", role: .cancel) {}
            } message: {
                Text("这笔账已经保存。")
            }
            .alert("保存失败", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(saveError ?? "请稍后再试。")
            }
            .onChange(of: kind) { _, newValue in
                selectedCategoryName = categoryName(for: newValue)
            }
            .onAppear {
                refreshSelections()
                prepareScreenshotForm()
            }
            .onChange(of: accounts.count) {
                refreshSelections()
            }
            .onChange(of: categories.count) {
                refreshSelections()
            }
            .onChange(of: selectedAccountName) {
                if kind == .transfer && selectedTargetAccountName == selectedAccountName {
                    selectedTargetAccountName = accounts.first { $0.name != selectedAccountName }?.name ?? selectedTargetAccountName
                }
            }
        }
    }

    private var monthlyHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("本月概览")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("¥\(monthlyExpense, specifier: "%.2f")")
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(monthlyRemainingBudget == nil ? "本月结余" : "预算剩余")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("¥\((monthlyRemainingBudget ?? monthlyBalance), specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle((monthlyRemainingBudget ?? monthlyBalance) >= 0 ? .green : .red)
                }
            }

            ProgressView(value: progressValue)
                .tint(.blue)
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var amountInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("金额")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("¥")
                    .font(.system(size: 34, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                    .textFieldStyle(.plain)
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var typePicker: some View {
        Picker("类型", selection: $kind) {
            ForEach(TransactionKind.allCases) { item in
                Text(LocalizedStringKey(item.title)).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("分类")
                .font(.headline)

            if kind == .transfer {
                Label("转账不会计入收入或支出统计", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(filteredCategories) { category in
                        Button {
                            selectedCategoryName = category.name
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: category.symbolName)
                                    .font(.title3)
                                Text(LocalizedStringKey(category.name))
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 82)
                            .background(selectedCategoryName == category.name ? Color.blue.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedCategoryName == category.name ? .blue : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var details: some View {
        VStack(spacing: 0) {
            TextField("备注，例如 午餐、咖啡、打车", text: $note)
                .textFieldStyle(.plain)
                .padding(.vertical, 16)

            Divider()

            DatePicker("日期", selection: $date, displayedComponents: .date)
                .padding(.vertical, 12)

            Divider()

            Picker("账户", selection: $selectedAccountName) {
                ForEach(accounts) { account in
                    Label(LocalizedStringKey(account.name), systemImage: account.symbolName).tag(account.name)
                }
            }
            .padding(.vertical, 12)

            if kind == .transfer {
                Divider()

                Picker("转入账户", selection: $selectedTargetAccountName) {
                    ForEach(accounts) { account in
                        Label(LocalizedStringKey(account.name), systemImage: account.symbolName).tag(account.name)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var saveButton: some View {
        Button {
            saveTransaction()
        } label: {
            Text("完成")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!canSave)
    }

    private var canSave: Bool {
        guard amount > 0 else {
            return false
        }

        if kind == .transfer {
            return selectedAccountName != selectedTargetAccountName && accounts.count > 1
        }

        return !selectedCategoryName.isEmpty
    }

    private var progressValue: Double {
        if monthlyBudget > 0 {
            return min(monthlyExpense / monthlyBudget, 1)
        }

        return monthlyIncome > 0 ? min(monthlyExpense / monthlyIncome, 1) : 0
    }

    private func saveTransaction() {
        guard canSave else {
            saveError = kind == .transfer ? "转账需要选择两个不同账户。" : "请输入有效金额和分类。"
            return
        }

        let transaction = LedgerTransaction(
            kind: kind,
            amount: amount,
            categoryName: kind == .transfer ? "转账" : selectedCategoryName,
            accountName: selectedAccountName,
            targetAccountName: kind == .transfer ? selectedTargetAccountName : nil,
            note: note.isEmpty ? selectedCategoryName : note,
            date: date
        )
        modelContext.insert(transaction)
        do {
            try modelContext.save()
            amountText = ""
            note = ""
            showSaved = true
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func refreshSelections() {
        selectedCategoryName = categoryName(for: kind)
        selectedAccountName = accounts.first(where: \.isDefault)?.name ?? accounts.first?.name ?? "微信"

        let target = accounts.first { $0.name != selectedAccountName } ?? accounts.first
        selectedTargetAccountName = target?.name ?? selectedAccountName
    }

    private func prepareScreenshotForm() {
        guard ScreenshotMode.isEnabled, amountText.isEmpty else {
            return
        }

        kind = .expense
        amountText = "36.00"
        selectedCategoryName = "餐饮"
        selectedAccountName = accounts.first(where: \.isDefault)?.name ?? accounts.first?.name ?? "微信"
        note = String(localized: "餐饮")
    }

    private func categoryName(for kind: TransactionKind) -> String {
        if kind == .transfer {
            return "转账"
        }

        return categories
            .filter { $0.kind == kind }
            .sorted { $0.sortIndex < $1.sortIndex }
            .first?.name ?? (kind == .income ? "工资" : "餐饮")
    }
}
