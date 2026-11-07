@preconcurrency import AppKit
import CoreFoundation

private let lfrToolsDarwinNotificationCallback: CFNotificationCallback = {
    _, observer, name, _, _ in
    guard let observer, let name else { return }
    let integration = Unmanaged<LFRToolsMenuIntegration>.fromOpaque(observer).takeUnretainedValue()
    let notificationName = name.rawValue as String
    Task { @MainActor in integration.receiveDarwinNotification(named: notificationName) }
}

@MainActor
final class LFRToolsMenuIntegration: ObservableObject {
    nonisolated static let lfrToolsBundleIdentifier = "com.luisroquette.ThinQMenuBar"
    nonisolated static let hideMenuBarExtraNotification = Notification.Name(
        "br.com.lfrprojects.NotchAgent.lfrToolsHideMenuBarExtra"
    )
    nonisolated static let showMenuBarExtraNotification = Notification.Name(
        "br.com.lfrprojects.NotchAgent.lfrToolsShowMenuBarExtra"
    )

    @Published var isMenuBarExtraInserted: Bool
    private var hideObserver: NSObjectProtocol?
    private var showObserver: NSObjectProtocol?
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
        showObserver = DistributedNotificationCenter.default().addObserver(
            forName: Self.showMenuBarExtraNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isMenuBarExtraInserted = true }
        }
        let darwinCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            darwinCenter,
            observer,
            lfrToolsDarwinNotificationCallback,
            CFNotificationName(Self.hideMenuBarExtraNotification.rawValue as CFString).rawValue,
            nil,
            .deliverImmediately
        )
        CFNotificationCenterAddObserver(
            darwinCenter,
            observer,
            lfrToolsDarwinNotificationCallback,
            CFNotificationName(Self.showMenuBarExtraNotification.rawValue as CFString).rawValue,
            nil,
            .deliverImmediately
        )
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
        if let showObserver {
            DistributedNotificationCenter.default().removeObserver(showObserver)
        }
        if let terminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(terminationObserver)
        }
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    func receiveDarwinNotification(named name: String) {
        if name == Self.hideMenuBarExtraNotification.rawValue {
            isMenuBarExtraInserted = false
        } else if name == Self.showMenuBarExtraNotification.rawValue {
            isMenuBarExtraInserted = true
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
