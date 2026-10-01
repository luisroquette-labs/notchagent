import Foundation
#if !APP_STORE
import Sparkle
#endif

@MainActor
final class AppUpdateController {
    #if APP_STORE
    var isConfigured: Bool { false }
    var isManagedByStore: Bool { true }

    init(bundle: Bundle = .main) {}

    func checkForUpdates() {}
    #else
    private let controller: SPUStandardUpdaterController?

    var isConfigured: Bool { controller != nil }
    var isManagedByStore: Bool { false }

    init(bundle: Bundle = .main) {
        guard BundleContext.isBundledApp,
              let feed = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
              let url = URL(string: feed),
              url.scheme == "https",
              bundle.object(forInfoDictionaryKey: "SUPublicEDKey") is String
        else {
            controller = nil
            return
        }

        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
    #endif
}
