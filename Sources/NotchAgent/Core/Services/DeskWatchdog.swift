import ServiceManagement

/// Keeps NotchAgent alive across crashes for customers who own a physical
/// Desk. A blank display with no way to explain itself is worse than a
/// silent app quit, since the hardware can only show "STALE" — it can't
/// tell the user the host process died. Scoped to Desk owners only: most
/// installs are pure software users, and registering a background
/// relaunch agent they never asked for would be unrequested overhead.
///
/// Independent of `LoginItem` (which only launches at login). This uses
/// `KeepAlive.SuccessfulExit = false`, which relaunches after a crash or
/// force-kill but not after `NSApp.terminate(nil)` — a clean quit exits 0.
@MainActor
enum DeskWatchdog {
    private static let plistName = "br.com.lfrprojects.notchagent.watchdog.plist"

    static var isAvailable: Bool { BundleContext.isBundledApp }

    static var isRegistered: Bool {
        guard isAvailable else { return false }
        return SMAppService.agent(plistName: plistName).status == .enabled
    }

    /// Idempotent — safe to call on every successful Desk handshake. Also
    /// retires the plain `LoginItem` registration if it's active: this
    /// agent's own RunAtLoad already covers "launch at login", and leaving
    /// both registered would double-launch the app at every future login
    /// (found live: registering this while `SMAppService.mainApp` was still
    /// enabled left two independent login-time launch paths pointed at the
    /// same app).
    static func ensureRegistered() {
        guard isAvailable, !isRegistered else { return }
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        }
        do {
            try SMAppService.agent(plistName: plistName).register()
            Log.app.info("Desk watchdog registered")
        } catch {
            Log.app.error("Desk watchdog registration failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func unregister() {
        guard isAvailable, isRegistered else { return }
        try? SMAppService.agent(plistName: plistName).unregister()
    }
}
