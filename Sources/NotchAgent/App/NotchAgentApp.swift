import SwiftUI

@main
struct NotchAgentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var lfrToolsIntegration = LFRToolsMenuIntegration()

    var body: some Scene {
        MenuBarExtra(isInserted: $lfrToolsIntegration.isMenuBarExtraInserted) {
            MenuBarContentView()
                .environment(AppEnvironment.shared.store)
                .environment(AppEnvironment.shared.preferences)
                .environment(AppEnvironment.shared.router)
                .environmentObject(AppEnvironment.shared.spending)
        } label: {
            MenuBarLabelView()
                .environment(AppEnvironment.shared.store)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    AppEnvironment.shared.router.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
