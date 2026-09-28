import Foundation

enum StoreDataFolder: String, CaseIterable, Sendable {
    case claudeCode
    case claudeDesktop
    case codex

    var expectedFolderName: String {
        switch self {
        case .claudeCode: ".claude"
        case .claudeDesktop: "Claude"
        case .codex: ".codex"
        }
    }

    var dataSubpath: String {
        switch self {
        case .claudeCode: "projects"
        case .claudeDesktop: "local-agent-mode-sessions"
        case .codex: "sessions"
        }
    }
}

enum SandboxBookmarkError: LocalizedError, Equatable {
    case unexpectedFolder(expected: String)

    var errorDescription: String? {
        switch self {
        case let .unexpectedFolder(expected):
            "Select the \(expected) folder."
        }
    }
}

/// Persistent read-only roots selected by the user in the App Store build.
/// Resolved URLs stay active for the process lifetime because providers scan
/// them on a schedule, not only while the settings panel is open.
final class SandboxBookmarkStore: @unchecked Sendable {
    static let shared = SandboxBookmarkStore()

    private let defaults: UserDefaults
    private let keyPrefix: String
    private let lock = NSLock()
    private var activeRoots: [StoreDataFolder: URL] = [:]

    init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "appStore.securityScopedBookmark"
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    func grant(_ folder: StoreDataFolder, selectedRoot: URL) throws {
        guard selectedRoot.lastPathComponent == folder.expectedFolderName else {
            throw SandboxBookmarkError.unexpectedFolder(expected: folder.expectedFolderName)
        }
        let data = try selectedRoot.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        lock.lock()
        defer { lock.unlock() }
        stopAccessLocked(folder)
        defaults.set(data, forKey: key(for: folder))
    }

    func revoke(_ folder: StoreDataFolder) {
        lock.lock()
        defer { lock.unlock() }
        stopAccessLocked(folder)
        defaults.removeObject(forKey: key(for: folder))
    }

    func selectedRoot(for folder: StoreDataFolder) -> URL? {
        lock.lock()
        defer { lock.unlock() }
        if let active = activeRoots[folder] { return active }
        guard let data = defaults.data(forKey: key(for: folder)) else { return nil }

        var stale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
            guard url.lastPathComponent == folder.expectedFolderName else {
                defaults.removeObject(forKey: key(for: folder))
                return nil
            }
            if stale {
                let refreshed = try url.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                defaults.set(refreshed, forKey: key(for: folder))
            }
            _ = url.startAccessingSecurityScopedResource()
            activeRoots[folder] = url
            return url
        } catch {
            defaults.removeObject(forKey: key(for: folder))
            return nil
        }
    }

    func dataURL(for folder: StoreDataFolder) -> URL? {
        selectedRoot(for: folder)?.appendingPathComponent(folder.dataSubpath, isDirectory: true)
    }

    var claudeRoots: [URL] {
        [.claudeCode, .claudeDesktop].compactMap(dataURL(for:))
    }

    var codexRoot: URL? {
        dataURL(for: .codex)
    }

    private func key(for folder: StoreDataFolder) -> String {
        "\(keyPrefix).\(folder.rawValue)"
    }

    private func stopAccessLocked(_ folder: StoreDataFolder) {
        activeRoots.removeValue(forKey: folder)?.stopAccessingSecurityScopedResource()
    }
}
