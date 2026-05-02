import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SiriShortcutsView()
                    } label: {
                        Label("Siri 与快捷指令", systemImage: "waveform")
                    }

                    Label("预算", systemImage: "gauge.with.dots.needle.33percent")
                    Label("分类管理", systemImage: "square.grid.2x2.fill")
                    Label("账户管理", systemImage: "creditcard.fill")
                }

                Section {
                    Label("隐私锁", systemImage: "faceid")
                    Label("数据备份", systemImage: "icloud.fill")
                    Label("导出 CSV", systemImage: "square.and.arrow.up")
                }
            }
            .navigationTitle("我的")
        }
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
