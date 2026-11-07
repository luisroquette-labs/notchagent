@preconcurrency import AppKit

@MainActor
final class LFRToolsMenuIntegration: ObservableObject {
    nonisolated static let lfrToolsBundleIdentifier = "com.luisroquette.ThinQMenuBar"
    nonisolated static let hideMenuBarExtraNotification = Notification.Name(
        "br.com.lfrprojects.NotchAgent.lfrToolsHideMenuBarExtra"
    )

    @Published var isMenuBarExtraInserted: Bool
    private var observer: NSObjectProtocol?

    init(lfrToolsRunning: Bool? = nil) {
        let isRunning = lfrToolsRunning ?? !NSRunningApplication.runningApplications(
            withBundleIdentifier: Self.lfrToolsBundleIdentifier
        ).isEmpty
        isMenuBarExtraInserted = Self.shouldInsertMenuBarExtra(lfrToolsRunning: isRunning)
        observer = DistributedNotificationCenter.default().addObserver(
            forName: Self.hideMenuBarExtraNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isMenuBarExtraInserted = false }
        }
    }

    deinit {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    nonisolated static func shouldInsertMenuBarExtra(lfrToolsRunning: Bool) -> Bool {
        !lfrToolsRunning
    }
}
