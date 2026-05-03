import LocalAuthentication
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("privacyLockEnabled") private var privacyLockEnabled = false
    @State private var selectedTab = ScreenshotMode.selectedTab
    @State private var isUnlocked = false
    @State private var authError: String?

    var body: some View {
        if ScreenshotMode.isEnabled && selectedTab == 4 {
            SiriShortcutsView()
                .task {
                    SeedData.ensureScreenshotData(in: modelContext)
                }
        } else {
            TabView(selection: $selectedTab) {
            AddTransactionView()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .tag(0)

            TransactionsView()
                .tabItem {
                    Label("明细", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
            .tint(.blue)
            .task {
                if ScreenshotMode.isEnabled {
                    SeedData.ensureScreenshotData(in: modelContext)
                } else {
                    SeedData.ensureDefaults(in: modelContext)
                    if privacyLockEnabled {
                        authenticate()
                    } else {
                        isUnlocked = true
                    }
                }
            }
            .overlay {
                if shouldShowPrivacyLock {
                    PrivacyLockView(errorMessage: authError) {
                        authenticate()
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    if privacyLockEnabled {
                        authenticate()
                    }
                } else if newPhase == .background {
                    isUnlocked = false
                }
            }
            .onChange(of: privacyLockEnabled) { _, enabled in
                isUnlocked = !enabled
                if enabled {
                    authenticate()
                }
            }
        }
    }

    private var shouldShowPrivacyLock: Bool {
        privacyLockEnabled && !isUnlocked && !ScreenshotMode.isEnabled
    }

    private func authenticate() {
        guard privacyLockEnabled, !ScreenshotMode.isEnabled else {
            isUnlocked = true
            return
        }

        let context = LAContext()
        var error: NSError?
        let reason = String(localized: "解锁简单账本")

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authError = error?.localizedDescription
            isUnlocked = false
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            Task { @MainActor in
                isUnlocked = success
                authError = success ? nil : error?.localizedDescription
            }
        }
    }
}

private struct PrivacyLockView: View {
    var errorMessage: String?
    var unlock: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.blue)
            Text("简单账本已锁定")
                .font(.title2.bold())
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Button("解锁") {
                unlock()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
