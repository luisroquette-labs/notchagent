import AppKit
import ServiceManagement
import UserNotifications
import AgentMeterCore

/// Both integrations below require a real .app bundle (see Scripts/make-app.sh).
/// When running unbundled (`swift run`), they report unavailable and the UI
/// explains why instead of failing.
@MainActor
enum BundleContext {
    static var isBundledApp: Bool {
        Bundle.main.bundleURL.pathExtension == "app" && Bundle.main.bundleIdentifier != nil
    }
}

/// Launch-at-login via SMAppService (macOS 13+).
@MainActor
enum LoginItem {
    static var isAvailable: Bool { BundleContext.isBundledApp }

    /// True if either the plain login item or the Desk crash-watchdog (which
    /// also launches at login, as a side effect of its own RunAtLoad) is
    /// registered — either one means the app launches at login.
    static var isEnabled: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled || DeskWatchdog.isRegistered
    }

    static func setEnabled(_ enabled: Bool) {
        guard isAvailable else { return }
        do {
            if enabled {
                // Desk watchdog already covers this — registering the plain
                // login item too would double-launch the app at login.
                if !DeskWatchdog.isRegistered {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
                DeskWatchdog.unregister()
            }
            Log.app.info("launch at login \(enabled ? "enabled" : "disabled", privacy: .public)")
        } catch {
            Log.app.error("launch at login failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// System notifications for warning/critical transitions. All UNUserNotification
/// calls stay behind the bundle guard — touching the center unbundled crashes.
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private var authorizationRequested = false
    private var deskCategoryRegistered = false
    /// Fired when the user taps "Mostrar meus dados" on the Desk-detected
    /// notification (or the notification itself, as a fallback tap target).
    var onDeskMirroringRequested: (() -> Void)?

    static var isAvailable: Bool { BundleContext.isBundledApp }

    override init() {
        super.init()
        guard Self.isAvailable else { return }
        UNUserNotificationCenter.current().delegate = self
    }

    func post(_ alert: ProviderAlert, settings: AppSettings) {
        guard Self.isAvailable, settings.notificationsEnabled, alert.level > .normal else { return }
        let center = UNUserNotificationCenter.current()

        if !authorizationRequested {
            authorizationRequested = true
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                Log.app.info("notification authorization: \(granted, privacy: .public)")
            }
        }

        let content = UNMutableNotificationContent()
        content.title = alert.level == .critical ? "Quota critical" : "Quota warning"
        content.body = alert.message
        if alert.level == .critical {
            content.sound = .default
        }
        center.add(UNNotificationRequest(
            identifier: "quota-\(alert.provider.rawValue)-\(alert.level.rawValue)",
            content: content,
            trigger: nil
        ))
    }

    func postRestored(_ moment: RestoreMoment, settings: AppSettings) {
        guard Self.isAvailable, settings.notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Session restored"
        content.body = moment.message
        content.sound = .default
        center.add(UNNotificationRequest(
            identifier: "restore-\(moment.provider.rawValue)-\(Int(moment.firedAt.timeIntervalSince1970))",
            content: content,
            trigger: nil
        ))
    }

    func postBudget(_ alert: MonthlyBudgetAlert, settings: AppSettings) {
        guard Self.isAvailable, settings.notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = alert.level == .exceeded ? "Orçamento excedido" : "Orçamento de IA em risco"
        content.body = "Previsão mensal em \(Int(alert.percent.rounded()))% do orçamento."
        if alert.level == .critical || alert.level == .exceeded { content.sound = .default }
        center.add(UNNotificationRequest(
            identifier: "budget-\(alert.level.rawValue)-\(Calendar.current.component(.month, from: .now))",
            content: content,
            trigger: nil
        ))
    }

    /// Fired once per Desk that connects for the first time while mirroring
    /// is still off — the opt-in ask itself, one tap away, no menu to find.
    func postDeskDetected() {
        guard Self.isAvailable else { return }
        let center = UNUserNotificationCenter.current()

        if !authorizationRequested {
            authorizationRequested = true
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                Log.app.info("notification authorization: \(granted, privacy: .public)")
            }
        }
        if !deskCategoryRegistered {
            deskCategoryRegistered = true
            let enable = UNNotificationAction(
                identifier: Self.deskEnableActionID,
                title: "Mostrar meus dados",
                options: [.foreground]
            )
            center.setNotificationCategories([
                UNNotificationCategory(identifier: Self.deskCategoryID, actions: [enable], intentIdentifiers: [])
            ])
        }

        let content = UNMutableNotificationContent()
        content.title = "NotchAgent Desk detectada"
        content.body = "Toque para mostrar sua quota na tela física."
        content.categoryIdentifier = Self.deskCategoryID
        center.add(UNNotificationRequest(identifier: "desk-detected", content: content, trigger: nil))
    }

    private nonisolated static let deskCategoryID = "DESK_DETECTED"
    private nonisolated static let deskEnableActionID = "ENABLE_DESK_MIRRORING"

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard response.notification.request.content.categoryIdentifier == Self.deskCategoryID,
              response.actionIdentifier == Self.deskEnableActionID
                  || response.actionIdentifier == UNNotificationDefaultActionIdentifier
        else { return }
        Task { @MainActor in self.onDeskMirroringRequested?() }
    }
}
