import Foundation

/// Persists the last valid snapshot per provider so the UI has data instantly
/// on launch, before the first refresh completes.
actor SnapshotStore {
    private let fileURL: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(fileURL: URL = AppPaths.appSupport.appendingPathComponent("snapshots.json")) {
        self.fileURL = fileURL
    }

    func load() -> [ProviderID: UsageSnapshot] {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshots = try? decoder.decode([ProviderID: UsageSnapshot].self, from: data)
        else { return [:] }
        guard DistributionChannel.isAppStore, var claude = snapshots[.claudeCode] else {
            return snapshots
        }
        // Older Store builds persisted token-budget estimates as quota percentages.
        claude.session?.usedPercent = nil
        claude.session?.namedQuotas = nil
        claude.weekly?.usedPercent = nil
        claude.weekly?.namedQuotas = nil
        claude.quotaStatus = nil
        var sanitized = snapshots
        sanitized[.claudeCode] = claude
        return sanitized
    }

    func save(_ snapshots: [ProviderID: UsageSnapshot]) {
        do {
            let data = try encoder.encode(snapshots)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Log.persistence.error("snapshot save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
