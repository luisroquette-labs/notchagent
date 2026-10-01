import XCTest
@testable import NotchAgent

final class AppStoreDistributionTests: XCTestCase {
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
    }

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

    private func makeDefaults() throws -> UserDefaults {
        let suite = "AppStoreDistributionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
