import XCTest
@testable import NotchAgent

final class LFRToolsMenuIntegrationTests: XCTestCase {
    func testMenuBarExtraIsHiddenWhileLFRToolsRuns() {
        XCTAssertFalse(LFRToolsMenuIntegration.shouldInsertMenuBarExtra(lfrToolsRunning: true))
    }

    func testMenuBarExtraRemainsAvailableWithoutLFRTools() {
        XCTAssertTrue(LFRToolsMenuIntegration.shouldInsertMenuBarExtra(lfrToolsRunning: false))
    }

    func testNotificationContractMatchesLFRTools() {
        XCTAssertEqual(
            LFRToolsMenuIntegration.hideMenuBarExtraNotification.rawValue,
            "br.com.lfrprojects.NotchAgent.lfrToolsHideMenuBarExtra"
        )
    }

    func testMenuBarExtraReturnsAfterLFRToolsTerminates() async {
        await MainActor.run {
            let integration = LFRToolsMenuIntegration(lfrToolsRunning: true)
            XCTAssertFalse(integration.isMenuBarExtraInserted)

            integration.applicationTerminated(
                bundleIdentifier: LFRToolsMenuIntegration.lfrToolsBundleIdentifier,
                lfrToolsStillRunning: false
            )

            XCTAssertTrue(integration.isMenuBarExtraInserted)
        }
    }
}
