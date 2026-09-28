import Foundation

/// Resolves bundled assets across BOTH packaging worlds:
/// - the installed .app (make-app copies Resources into Bundle.main)
/// - a bare `swift run` / `swift test` (SwiftPM puts declared resources
///   into Bundle.module, under the copied directory's path)
///
/// REGRESSÃO: the mascots only ever loaded from Bundle.main, so every
/// `swift run` session silently fell back to procedural placeholders —
/// the "broken mascot" users saw for a whole debugging day.
enum AssetBundle {
    static func resourceNames(for name: String) -> [String] {
        let basename = URL(fileURLWithPath: name).lastPathComponent
        return basename == name ? [name] : [name, basename]
    }

    static func url(forResource name: String, withExtension ext: String) -> URL? {
        // Xcode flattens folder resources into Contents/Resources, while the
        // direct app and SwiftPM preserve the Mascots/ directory.
        for candidate in resourceNames(for: name) {
            if let url = Bundle.main.url(forResource: candidate, withExtension: ext) {
                return url
            }
        }
        #if SWIFT_PACKAGE
        for candidate in resourceNames(for: name) {
            if let url = Bundle.module.url(forResource: candidate, withExtension: ext) {
                return url
            }
            // SwiftPM .copy("Resources/Mascots") nests the files under the
            // copied directory's own name inside the module bundle.
            if let url = Bundle.module.url(forResource: "Resources/\(candidate)", withExtension: ext) {
                return url
            }
        }
        #endif
        return nil
    }
}
