import Foundation

enum AssetBundle {
    static func resourceNames(for name: String) -> [String] {
        let basename = URL(fileURLWithPath: name).lastPathComponent
        return basename == name ? [name] : [name, basename]
    }

    static func url(forResource name: String, withExtension ext: String) -> URL? {
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
            if let url = Bundle.module.url(forResource: "Resources/\(candidate)", withExtension: ext) {
                return url
            }
        }
        #endif
        return nil
    }
}
