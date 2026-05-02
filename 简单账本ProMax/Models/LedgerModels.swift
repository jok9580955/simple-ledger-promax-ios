import Foundation
import SwiftData

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "支出"
        case .income: "收入"
        case .transfer: "转账"
        }
    }
}

@Model
final class LedgerTransaction {
    var id: UUID
    var kindRawValue: String
    var amount: Double
    var categoryName: String
    var accountName: String
    var targetAccountName: String?
    var note: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        kind: TransactionKind,
        amount: Double,
        categoryName: String,
        accountName: String,
        targetAccountName: String? = nil,
        note: String,
        date: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.amount = amount
        self.categoryName = categoryName
        self.accountName = accountName
        self.targetAccountName = targetAccountName
        self.note = note
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRawValue) ?? .expense }
        set {
            kindRawValue = newValue.rawValue
            updatedAt = .now
        }
    }
}

@Model
final class LedgerCategory {
    var id: UUID
    var name: String
    var symbolName: String
    var kindRawValue: String
    var sortIndex: Int

    init(id: UUID = UUID(), name: String, symbolName: String, kind: TransactionKind, sortIndex: Int) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.kindRawValue = kind.rawValue
        self.sortIndex = sortIndex
    }

    var kind: TransactionKind {
        TransactionKind(rawValue: kindRawValue) ?? .expense
    }
}

@Model
final class LedgerAccount {
    var id: UUID
    var name: String
    var symbolName: String
    var isDefault: Bool
    var sortIndex: Int

    init(id: UUID = UUID(), name: String, symbolName: String, isDefault: Bool = false, sortIndex: Int) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.isDefault = isDefault
        self.sortIndex = sortIndex
    }
}

enum LedgerDefaults {
    static let expenseCategories: [(String, String)] = [
        ("餐饮", "fork.knife"),
        ("交通", "car.fill"),
        ("购物", "bag.fill"),
        ("住房", "house.fill"),
        ("娱乐", "sparkles.tv.fill"),
        ("医疗", "cross.case.fill"),
        ("学习", "book.fill"),
        ("人情", "gift.fill"),
        ("其他", "ellipsis.circle.fill")
    ]

    static let incomeCategories: [(String, String)] = [
        ("工资", "banknote.fill"),
        ("奖金", "party.popper.fill"),
        ("兼职", "briefcase.fill"),
        ("理财", "chart.line.uptrend.xyaxis"),
        ("其他收入", "plus.circle.fill")
    ]

    static let accounts: [(String, String)] = [
        ("微信", "message.fill"),
        ("支付宝", "qrcode"),
        ("银行卡", "creditcard.fill"),
        ("现金", "wallet.pass.fill")
    ]
}

enum CategoryInferencer {
    static func inferExpenseCategory(from text: String) -> String {
        let normalized = text.lowercased()
        let rules: [(String, [String])] = [
            ("餐饮", ["饭", "餐", "咖啡", "奶茶", "早餐", "午餐", "晚餐", "外卖", "火锅", "面", "水果"]),
            ("交通", ["打车", "地铁", "公交", "高铁", "火车", "飞机", "停车", "加油", "滴滴"]),
            ("购物", ["买", "购物", "衣服", "鞋", "超市", "淘宝", "京东"]),
            ("住房", ["房租", "水费", "电费", "燃气", "物业"]),
            ("娱乐", ["电影", "游戏", "会员", "演唱会", "旅游"]),
            ("医疗", ["药", "医院", "体检", "挂号"]),
            ("学习", ["书", "课程", "学费", "培训"]),
            ("人情", ["红包", "礼物", "请客", "份子"])
        ]

        return rules.first { _, keywords in
            keywords.contains { normalized.contains($0) }
        }?.0 ?? "其他"
    }

    static func inferIncomeCategory(from text: String) -> String {
        let normalized = text.lowercased()
        if normalized.contains("工资") || normalized.contains("薪") {
            return "工资"
        }
        if normalized.contains("奖金") || normalized.contains("年终") {
            return "奖金"
        }
        if normalized.contains("兼职") || normalized.contains("外快") {
            return "兼职"
        }
        if normalized.contains("理财") || normalized.contains("利息") {
            return "理财"
        }
        return "其他收入"
    }
}
