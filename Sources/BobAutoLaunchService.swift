import Foundation
import ServiceManagement

enum BobAutoLaunchError: LocalizedError {
    case launcherNotFound

    var errorDescription: String? {
        switch self {
        case .launcherNotFound:
            return "Could not find the bundled Bob auto-launch helper. Please reinstall Bob Select Helper."
        }
    }
}

final class BobAutoLaunchService {
    static let shared = BobAutoLaunchService()

    static let launcherBundleIdentifier = "com.bryannelson.BobSelectHelper.Launcher"

    private init() {}

    private var service: SMAppService {
        SMAppService.loginItem(identifier: Self.launcherBundleIdentifier)
    }

    var status: SMAppService.Status {
        service.status
    }

    var isEnabledOrPendingApproval: Bool {
        switch status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }

    func enable() throws {
        switch status {
        case .enabled, .requiresApproval:
            return
        case .notFound:
            throw BobAutoLaunchError.launcherNotFound
        case .notRegistered:
            try service.register()
        @unknown default:
            try service.register()
        }
    }

    func disable(completion: @escaping (Error?) -> Void) {
        switch status {
        case .notRegistered, .notFound:
            completion(nil)
        case .enabled, .requiresApproval:
            service.unregister { error in
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        @unknown default:
            service.unregister { error in
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
