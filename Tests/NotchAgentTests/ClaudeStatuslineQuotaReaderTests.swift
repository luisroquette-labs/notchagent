import XCTest
@testable import NotchAgent

final class ClaudeStatuslineQuotaReaderTests: XCTestCase {
    func testReadsOfficialFiveHourAndSevenDayPercentages() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let reset = now.addingTimeInterval(3_600).timeIntervalSince1970
        let data = try JSONSerialization.data(withJSONObject: [
            "five_hour": ["used_percentage": 25.5, "resets_at": reset],
            "seven_day": ["used_percentage": 83, "resets_at": reset],
        ])
        let quota = try XCTUnwrap(ClaudeStatuslineQuotaReader.parse(data, fetchedAt: now, now: now))
        XCTAssertEqual(quota.sessionPercent, 25.5)
        XCTAssertEqual(quota.weeklyPercent, 83)
        XCTAssertEqual(quota.status, .warning)
        XCTAssertEqual(quota.limitingWindow, "seven_day")
    }

    func testRejectsInvalidAndExpiredWindows() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let data = try JSONSerialization.data(withJSONObject: [
            "five_hour": ["used_percentage": 137, "resets_at": now.addingTimeInterval(3600).timeIntervalSince1970],
            "seven_day": ["used_percentage": 20, "resets_at": now.addingTimeInterval(-1).timeIntervalSince1970],
        ])
        XCTAssertNil(ClaudeStatuslineQuotaReader.parse(data, fetchedAt: now, now: now))
    }

    func testRejectsStaleFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent(ClaudeStatuslineQuotaReader.fileName)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let data = try JSONSerialization.data(withJSONObject: [
            "five_hour": ["used_percentage": 35, "resets_at": now.addingTimeInterval(3600).timeIntervalSince1970],
        ])
        try data.write(to: file)
        try FileManager.default.setAttributes([.modificationDate: now.addingTimeInterval(-16 * 60)], ofItemAtPath: file.path)
        XCTAssertNil(ClaudeStatuslineQuotaReader.read(root: root, now: now))
    }
}
