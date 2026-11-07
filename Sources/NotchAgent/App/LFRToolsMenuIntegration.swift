@preconcurrency import AppKit

@MainActor
final class LFRToolsMenuIntegration: ObservableObject {
    nonisolated static let lfrToolsBundleIdentifier = "com.luisroquette.ThinQMenuBar"
    nonisolated static let hideMenuBarExtraNotification = Notification.Name(
        "br.com.lfrprojects.NotchAgent.lfrToolsHideMenuBarExtra"
    )

    @Published var isMenuBarExtraInserted: Bool
    private var hideObserver: NSObjectProtocol?
    private var terminationObserver: NSObjectProtocol?

    init(lfrToolsRunning: Bool? = nil) {
        let isRunning = lfrToolsRunning ?? !NSRunningApplication.runningApplications(
            withBundleIdentifier: Self.lfrToolsBundleIdentifier
        ).isEmpty
        isMenuBarExtraInserted = Self.shouldInsertMenuBarExtra(lfrToolsRunning: isRunning)
        hideObserver = DistributedNotificationCenter.default().addObserver(
            forName: Self.hideMenuBarExtraNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isMenuBarExtraInserted = false }
        }
        terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication else { return }
            Task { @MainActor in
                self?.applicationTerminated(
                    bundleIdentifier: application.bundleIdentifier,
                    lfrToolsStillRunning: !NSRunningApplication.runningApplications(
                        withBundleIdentifier: Self.lfrToolsBundleIdentifier
                    ).isEmpty
                )
            }
        }
    }

    deinit {
        if let hideObserver {
            DistributedNotificationCenter.default().removeObserver(hideObserver)
        }
        if let terminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(terminationObserver)
        }
    }

    func applicationTerminated(bundleIdentifier: String?, lfrToolsStillRunning: Bool) {
        guard bundleIdentifier == Self.lfrToolsBundleIdentifier else { return }
        isMenuBarExtraInserted = Self.shouldInsertMenuBarExtra(
            lfrToolsRunning: lfrToolsStillRunning
        )
    }

    nonisolated static func shouldInsertMenuBarExtra(lfrToolsRunning: Bool) -> Bool {
        !lfrToolsRunning
    }
}
