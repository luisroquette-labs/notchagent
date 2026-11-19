import XCTest
@testable import NotchAgent

final class ClaudeStatuslineQuotaReaderTests: XCTestCase {
    func testGuidedSetupAddsOnlyClaudeStatuslineAndIsIdempotent() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(".claude")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        let file = root.appendingPathComponent("settings.json")
        try #"{"permissions":{"allow":["Read"]},"language":"pt"}"#.write(to: file, atomically: true, encoding: .utf8)

        try ClaudeStatuslineSetup.install(root: root)
        let first = try Data(contentsOf: file)
        let settings = try XCTUnwrap(JSONSerialization.jsonObject(with: first) as? [String: Any])
        XCTAssertEqual((settings["permissions"] as? [String: [String]])?["allow"], ["Read"])
        XCTAssertEqual(settings["language"] as? String, "pt")
        XCTAssertTrue(ClaudeStatuslineSetup.isInstalled(root: root))
        try ClaudeStatuslineSetup.install(root: root)
        XCTAssertEqual(try Data(contentsOf: file), first)
    }

    func testGuidedSetupPreservesExistingCustomStatuslineAndInvalidSettings() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(".claude")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        let file = root.appendingPathComponent("settings.json")
        let custom = #"{"language":"en","statusLine":{"type":"command","command":"echo custom"}}"#
        try custom.write(to: file, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try ClaudeStatuslineSetup.install(root: root))
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), custom)
        try ClaudeStatuslineSetup.install(root: root, replaceExisting: true)
        let replaced = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        XCTAssertEqual(replaced["language"] as? String, "en")
        XCTAssertTrue(ClaudeStatuslineSetup.isInstalled(root: root))
        try "not json".write(to: file, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try ClaudeStatuslineSetup.install(root: root))
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "not json")
    }

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
