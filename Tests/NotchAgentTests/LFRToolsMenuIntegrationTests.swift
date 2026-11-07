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
}
