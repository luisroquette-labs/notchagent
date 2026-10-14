import XCTest
@testable import NotchAgent

final class AppStoreDistributionTests: XCTestCase {
    func testDistributionVersionsMatchTheirOwnTargets() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let directVersion = try String(contentsOf: root.appendingPathComponent("VERSION"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let storeVersion = try String(contentsOf: root.appendingPathComponent("APP_STORE_VERSION"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let project = try String(contentsOf: root.appendingPathComponent("project.yml"), encoding: .utf8)
        let direct = try XCTUnwrap(project.range(of: "\n  NotchAgent:\n"))
        let store = try XCTUnwrap(project.range(of: "\n  NotchAgentAppStore:\n"))
        let tests = try XCTUnwrap(project.range(of: "\n  NotchAgentTests:\n"))

        XCTAssertTrue(project[direct.upperBound..<store.lowerBound]
            .contains("CFBundleShortVersionString: \"\(directVersion)\""))
        XCTAssertTrue(project[store.upperBound..<tests.lowerBound]
            .contains("CFBundleShortVersionString: \"\(storeVersion)\""))
    }

    func testNativeSettingsCommandRoutesToWindowRouter() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let app = try String(
            contentsOf: root.appendingPathComponent("Sources/NotchAgent/App/NotchAgentApp.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(app.contains("CommandGroup(replacing: .appSettings)"))
        XCTAssertTrue(app.contains("AppEnvironment.shared.router.openSettings()"))
        XCTAssertTrue(app.contains(".keyboardShortcut(\",\", modifiers: .command)"))
    }

    @MainActor
    func testSettingsRouterOpensAndReusesOneWindow() {
        let application = NSApplication.shared
        let title = "NotchAgent — Settings"
        application.windows.filter { $0.title == title }.forEach { $0.close() }

        AppEnvironment.shared.router.openSettings()
        AppEnvironment.shared.router.openSettings()

        let windows = application.windows.filter { $0.title == title }
        XCTAssertEqual(windows.count, 1)
        XCTAssertTrue(windows[0].isVisible)
        windows[0].close()
    }

    func testStoreEntitlementsExcludeUnusedNetworkServerPermission() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("Resources/NotchAgentAppStore.entitlements"))
        let entitlements = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        XCTAssertNil(entitlements["com.apple.security.network.server"])
        XCTAssertEqual(entitlements["com.apple.security.network.client"] as? Bool, true)
        XCTAssertEqual(entitlements["com.apple.security.files.user-selected.read-write"] as? Bool, true)
        XCTAssertNil(entitlements["com.apple.security.files.user-selected.read-only"])
        let project = try String(contentsOf: root.appendingPathComponent("project.yml"), encoding: .utf8)
        XCTAssertFalse(project.contains("com.apple.security.network.server"))
    }

    func testDistributionFlagMatchesCompilationCondition() {
        #if APP_STORE
        XCTAssertTrue(DistributionChannel.isAppStore)
        #else
        XCTAssertFalse(DistributionChannel.isAppStore)
        #endif
    }

    @MainActor
    func testUpdateChannelMatchesDistribution() {
        let updates = AppUpdateController(bundle: .main)
        #if APP_STORE
        XCTAssertTrue(updates.isManagedByStore)
        XCTAssertFalse(updates.isConfigured)
        #else
        XCTAssertFalse(updates.isManagedByStore)
        #endif
    }

    func testFolderContractUsesExpectedParentsAndDataSubpaths() {
        XCTAssertEqual(StoreDataFolder.claudeCode.expectedFolderName, ".claude")
        XCTAssertEqual(StoreDataFolder.claudeCode.dataSubpath, "projects")
        XCTAssertEqual(StoreDataFolder.claudeDesktop.expectedFolderName, "Claude")
        XCTAssertEqual(StoreDataFolder.claudeDesktop.dataSubpath, "local-agent-mode-sessions")
        XCTAssertEqual(StoreDataFolder.codex.expectedFolderName, ".codex")
        XCTAssertEqual(StoreDataFolder.codex.dataSubpath, "sessions")
        let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)
        XCTAssertEqual(StoreDataFolder.codex.suggestedRoot(in: home).path, "/Users/example/.codex")
        XCTAssertEqual(StoreDataFolder.claudeCode.suggestedRoot(in: home).path, "/Users/example/.claude")
        XCTAssertEqual(StoreDataFolder.claudeDesktop.suggestedRoot(in: home).path,
                       "/Users/example/Library/Application Support/Claude")
    }

    func testGuidedSetupAppearsOnlyBeforeCompletionAndWithoutExistingAccess() {
        XCTAssertTrue(StoreOnboardingState.shouldPresent(completed: false, hasAuthorizedFolder: false))
        XCTAssertFalse(StoreOnboardingState.shouldPresent(completed: true, hasAuthorizedFolder: false))
        XCTAssertFalse(StoreOnboardingState.shouldPresent(completed: false, hasAuthorizedFolder: true))
    }

    func testSettingsRefreshesFolderStatusAfterGuidedAuthorization() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appendingPathComponent("Sources/NotchAgent/Features/Settings/StoreFolderAccessSection.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(source.contains(".onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in\n            language = .current\n            inspectAuthorizedFolders()"))
    }

    #if APP_STORE
    func testClaudeStoreCardDoesNotPresentLocalTokensAsQuota() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let card = try String(contentsOf: root.appendingPathComponent(
            "Sources/NotchAgent/Features/NotchOverlay/Components/ProviderCardView.swift"
        ), encoding: .utf8)
        let session = try XCTUnwrap(card.range(of: "private func sessionWindowBlock"))
        let weekly = try XCTUnwrap(card.range(of: "private func weeklyWindowBlock"))
        let nextSection = try XCTUnwrap(card.range(of: "private func namedQuotas"))
        let quotaBlocks = String(card[session.lowerBound..<nextSection.lowerBound])
        XCTAssertTrue(quotaBlocks.contains("COTA INDISPONÍVEL"))
        XCTAssertTrue(quotaBlocks.contains("COTA SEMANAL INDISPONÍVEL"))
        let storeSession = String(card[session.lowerBound..<weekly.lowerBound])
        XCTAssertFalse(storeSession.contains("localSessionTokens"))
        let storeWeekly = String(card[weekly.lowerBound..<nextSection.lowerBound])
        XCTAssertFalse(storeWeekly.contains("TOKENS LOCAIS"))
    }

    func testGuidedSetupUsesThreeLanguagesAndEnglishFallback() {
        XCTAssertEqual(SetupLanguage.preferred(for: "pt-BR"), .pt)
        XCTAssertEqual(SetupLanguage.preferred(for: "en-US"), .en)
        XCTAssertEqual(SetupLanguage.preferred(for: "es-ES"), .es)
        XCTAssertEqual(SetupLanguage.preferred(for: "fr-FR"), .en)
    }

    func testRestoredStoreSnapshotCannotShowOldEstimatedClaudeQuota() async throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("notchagent-store-snapshot-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let storage = SnapshotStore(fileURL: file)
        let old = UsageSnapshot(
            provider: .claudeCode,
            health: .ok,
            session: SessionUsage(tokens: TokenUsage(input: 500), usedPercent: 100),
            weekly: WeeklyUsage(tokens: TokenUsage(input: 1_000), usedPercent: 100),
            quotaStatus: .blocked
        )
        await storage.save([.claudeCode: old])

        let loaded = await storage.load()
        let restored = try XCTUnwrap(loaded[.claudeCode])
        XCTAssertEqual(restored.session?.tokens.total, 500)
        XCTAssertEqual(restored.weekly?.tokens.total, 1_000)
        XCTAssertNil(restored.session?.usedPercent)
        XCTAssertNil(restored.weekly?.usedPercent)
        XCTAssertNil(restored.quotaStatus)
        XCTAssertNil(GaugeMetric.from(restored))
    }

    @MainActor
    func testClosingGuidedSetupDoesNotRepeatOnNextLaunch() throws {
        let defaults = UserDefaults.standard
        let key = StoreOnboardingState.completedKey
        let previous = defaults.object(forKey: key)
        defer {
            if let previous { defaults.set(previous, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        defaults.removeObject(forKey: key)

        AppEnvironment.shared.router.openStoreOnboarding()
        let window = try XCTUnwrap(NSApplication.shared.windows.first {
            $0.title == "NotchAgent" && $0.isVisible
        })
        window.close()

        XCTAssertTrue(defaults.bool(forKey: key))
    }
    #endif

    func testBookmarkStoreRejectsWrongFolder() throws {
        let defaults = try makeDefaults()
        let store = SandboxBookmarkStore(defaults: defaults, keyPrefix: "test.bookmark")
        let wrong = FileManager.default.temporaryDirectory
            .appendingPathComponent("not-codex-\(UUID().uuidString)", isDirectory: true)

        XCTAssertThrowsError(try store.grant(.codex, selectedRoot: wrong)) { error in
            XCTAssertEqual(
                error as? SandboxBookmarkError,
                .unexpectedFolder(expected: ".codex")
            )
        }
        XCTAssertNil(store.codexRoot)
    }

    func testCorruptBookmarkIsRemovedInsteadOfRetried() throws {
        let defaults = try makeDefaults()
        let prefix = "test.bookmark"
        defaults.set(Data([0x00, 0x01]), forKey: "\(prefix).codex")
        let store = SandboxBookmarkStore(defaults: defaults, keyPrefix: prefix)

        XCTAssertNil(store.selectedRoot(for: .codex))
        XCTAssertNil(defaults.data(forKey: "\(prefix).codex"))
    }

    func testFolderInspectionSeparatesAuthorizationFromUsableData() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("notchagent-setup-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        XCTAssertEqual(StoreFolderInspector.inspect(.codex, root: root), .missingSessionsFolder)

        let sessions = root.appendingPathComponent("sessions", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        XCTAssertEqual(StoreFolderInspector.inspect(.codex, root: root), .noRecentSessions)

        let empty = sessions.appendingPathComponent("rollout-empty.jsonl")
        try Data("{}\n".utf8).write(to: empty)
        XCTAssertEqual(StoreFolderInspector.inspect(.codex, root: root), .noUsageRecords)

        let fixture = try XCTUnwrap(Bundle.module.url(
            forResource: "codex-rollout", withExtension: "jsonl", subdirectory: "Fixtures"
        ))
        let valid = sessions.appendingPathComponent("rollout-valid.jsonl")
        try FileManager.default.copyItem(at: fixture, to: valid)
        try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: valid.path)
        guard case let .found(files, latest) = StoreFolderInspector.inspect(.codex, root: root) else {
            return XCTFail("A valid Codex rollout must be recognized independently of the bookmark")
        }
        XCTAssertEqual(files, 2)
        XCTAssertNotNil(latest)
    }

    func testClaudeDesktopInspectionDoesNotBorrowClaudeCodeData() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("notchagent-desktop-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let sessions = root.appendingPathComponent("local-agent-mode-sessions", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        XCTAssertEqual(StoreFolderInspector.inspect(.claudeDesktop, root: root), .noRecentSessions)

        let fixture = try XCTUnwrap(Bundle.module.url(
            forResource: "claude-session", withExtension: "jsonl", subdirectory: "Fixtures"
        ))
        let valid = sessions.appendingPathComponent("session.jsonl")
        try FileManager.default.copyItem(at: fixture, to: valid)
        try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: valid.path)
        guard case let .found(files, _) = StoreFolderInspector.inspect(.claudeDesktop, root: root) else {
            return XCTFail("Claude Desktop must use only its own selected folder")
        }
        XCTAssertEqual(files, 1)
    }

    func testFolderInspectionReportsUnreadableSession() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("notchagent-unreadable-\(UUID().uuidString)", isDirectory: true)
        let sessions = root.appendingPathComponent("sessions", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        let file = sessions.appendingPathComponent("rollout-unreadable.jsonl")
        try Data("{}\n".utf8).write(to: file)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: file.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
            try? FileManager.default.removeItem(at: root)
        }

        XCTAssertEqual(StoreFolderInspector.inspect(.codex, root: root), .readFailed)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suite = "AppStoreDistributionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
