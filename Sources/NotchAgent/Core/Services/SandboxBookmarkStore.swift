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

    func suggestedRoot(in userHome: URL) -> URL {
        let parent = self == .claudeDesktop
            ? userHome.appendingPathComponent("Library/Application Support", isDirectory: true)
            : userHome
        return parent.appendingPathComponent(expectedFolderName, isDirectory: true)
    }
}

enum SandboxBookmarkError: LocalizedError, Equatable {
    case unexpectedFolder(expected: String)
    case accessDenied

    var errorDescription: String? {
        switch self {
        case let .unexpectedFolder(expected):
            "Select the \(expected) folder."
        case .accessDenied:
            "Folder access was not granted. Select the folder again."
        }
    }
}

enum StoreFolderReadiness: Equatable, Sendable {
    case checking
    case missingSessionsFolder
    case noRecentSessions
    case noUsageRecords
    case readFailed
    case found(sessionFiles: Int, verifiedActivity: Date?)
}

enum StoreFolderInspector {
    static func inspect(_ folder: StoreDataFolder, root: URL, now: Date = Date()) -> StoreFolderReadiness {
        let sessions = root.appendingPathComponent(folder.dataSubpath, isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: sessions.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .missingSessionsFolder
        }
        guard FileManager.default.isReadableFile(atPath: sessions.path) else { return .readFailed }
        let files = recentFiles(under: sessions, ext: "jsonl", modifiedAfter: now.addingTimeInterval(-8 * 24 * 3600))
        guard !files.isEmpty else { return .noRecentSessions }

        var readErrors = 0
        for file in files {
            do {
                switch folder {
                case .codex:
                    if let info = try CodexRolloutParser.latestTokenInfo(at: file) {
                        return .found(
                            sessionFiles: files.count,
                            verifiedActivity: info.timestamp ?? CodexProvider.rolloutStart(from: file)
                        )
                    }
                case .claudeCode, .claudeDesktop:
                    if let activity = try ClaudeTranscriptParser.parseFile(at: file).stat.lastActivity {
                        return .found(sessionFiles: files.count, verifiedActivity: activity)
                    }
                }
            } catch {
                readErrors += 1
            }
        }
        return readErrors > 0 ? .readFailed : .noUsageRecords
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
        var stale = false
        let resolved = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        )
        guard resolved.lastPathComponent == folder.expectedFolderName else {
            throw SandboxBookmarkError.unexpectedFolder(expected: folder.expectedFolderName)
        }
        guard resolved.startAccessingSecurityScopedResource() else {
            throw SandboxBookmarkError.accessDenied
        }
        lock.lock()
        defer { lock.unlock() }
        stopAccessLocked(folder)
        defaults.set(data, forKey: key(for: folder))
        activeRoots[folder] = resolved
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
            guard url.startAccessingSecurityScopedResource() else {
                defaults.removeObject(forKey: key(for: folder))
                return nil
            }
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
