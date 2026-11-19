import Foundation

/// Reads the quota subset exported by Claude Code's user-configured status line.
/// The App Store app never runs the status-line command or accesses credentials.
enum ClaudeStatuslineQuotaReader {
    static let fileName = ".notchagent-quota.json"
    private static let maxAge: TimeInterval = 15 * 60
    private static let maxBytes = 4_096

    static func read(root: URL, now: Date = Date()) -> ClaudeQuota? {
        let file = root.appendingPathComponent(fileName)
        guard let values = try? file.resourceValues(forKeys: [
            .isRegularFileKey, .fileSizeKey, .contentModificationDateKey,
        ]), values.isRegularFile == true,
              let size = values.fileSize, size <= maxBytes,
              let modified = values.contentModificationDate,
              now.timeIntervalSince(modified) >= 0,
              now.timeIntervalSince(modified) <= maxAge,
              let data = try? Data(contentsOf: file), data.count <= maxBytes
        else { return nil }
        return parse(data, fetchedAt: modified, now: now)
    }

    static func parse(_ data: Data, fetchedAt: Date, now: Date = Date()) -> ClaudeQuota? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        func window(_ name: String) -> (Double?, Date?) {
            guard let object = root[name] as? [String: Any],
                  let rawPercent = object["used_percentage"] as? NSNumber,
                  let rawReset = object["resets_at"] as? NSNumber
            else { return (nil, nil) }
            let percent = rawPercent.doubleValue
            let reset = Date(timeIntervalSince1970: rawReset.doubleValue)
            guard percent.isFinite, (0...100).contains(percent), reset > now else { return (nil, nil) }
            return (percent, reset)
        }

        let session = window("five_hour")
        let weekly = window("seven_day")
        guard session.0 != nil || weekly.0 != nil else { return nil }
        let highest = [session.0, weekly.0].compactMap { $0 }.max()!
        let status: QuotaStatus = highest >= 100 ? .blocked : highest >= 80 ? .warning : .ok
        return ClaudeQuota(
            sessionPercent: session.0,
            weeklyPercent: weekly.0,
            sessionResetsAt: session.1,
            weeklyResetsAt: weekly.1,
            status: status,
            limitingWindow: (session.0 ?? -1) >= (weekly.0 ?? -1) ? "five_hour" : "seven_day",
            fetchedAt: fetchedAt
        )
    }
}
