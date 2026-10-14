import Foundation

enum ClaudeStatuslineSetupError: Error {
    case invalidSettings
    case existingStatusline
    case unexpectedFile
    case writeFailed
}

/// Changes only the user-selected Claude Code settings file. Folder bookmarks
/// remain read-only after the picker closes.
enum ClaudeStatuslineSetup {
    static let command = #"/usr/bin/plutil -extract rate_limits json -o "$HOME/.claude/.notchagent-quota.json" - >/dev/null 2>&1; printf 'NotchAgent'"#
    private static let maxSettingsBytes = 1_048_576

    static func isInstalled(root: URL) -> Bool {
        guard let settings = try? readSettings(at: root.appendingPathComponent("settings.json")),
              let statusLine = settings["statusLine"] as? [String: Any],
              let command = statusLine["command"] as? String else { return false }
        return command.contains(".notchagent-quota.json") && command.contains("/usr/bin/plutil")
    }

    static func install(root: URL, replaceExisting: Bool = false) throws {
        guard root.lastPathComponent == ".claude" else { throw ClaudeStatuslineSetupError.unexpectedFile }
        let file = root.appendingPathComponent("settings.json")
        var settings = try readSettings(at: file)
        if let existing = settings["statusLine"] {
            if let line = existing as? [String: Any],
               let existingCommand = line["command"] as? String,
               existingCommand == command ||
                (existingCommand.contains(".notchagent-quota.json") && existingCommand.contains("/usr/bin/plutil")) {
                return
            }
            guard replaceExisting else { throw ClaudeStatuslineSetupError.existingStatusline }
        }
        settings["statusLine"] = ["type": "command", "command": command]
        let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .withoutEscapingSlashes])
        do { try data.write(to: file, options: .atomic) }
        catch { throw ClaudeStatuslineSetupError.writeFailed }
    }

    private static func readSettings(at file: URL) throws -> [String: Any] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory) else { return [:] }
        guard !isDirectory.boolValue,
              let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]),
              values.isRegularFile == true, values.isSymbolicLink != true,
              let size = values.fileSize, size <= maxSettingsBytes,
              let data = try? Data(contentsOf: file),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw ClaudeStatuslineSetupError.invalidSettings }
        return object
    }
}
