import Foundation

enum ActivationMode: String {
    case hover
    case click
}

enum PanelPosition: String {
    case belowRight
    case aboveRight
    case belowLeft
    case aboveLeft
}

enum InputBoxState: String {
    case last
    case alwaysFold
    case alwaysUnfold
}

enum AppFilterMode: String {
    case allowAll
    case whitelist
    case blacklist
}

final class Settings {
    static let shared = Settings()

    private enum Key {
        static let enabled = "enabled"
        static let activationMode = "activationMode"
        static let hoverDelay = "hoverDelay"
        static let iconSize = "iconSize"
        static let autoHideDelay = "autoHideDelay"
        static let panelPosition = "panelPosition"
        static let copyFallback = "copyFallback"
        static let inputBoxState = "inputBoxState"
        static let didShowWelcome = "didShowWelcome"
        static let didConfigureBobAutoLaunch = "didConfigureBobAutoLaunch"
        static let appFilterMode = "appFilterMode"
        static let whitelistedApps = "whitelistedApps"
        static let blacklistedApps = "blacklistedApps"
    }

    private let defaults = UserDefaults.standard

    private init() {}

    var isEnabled: Bool {
        get {
            if defaults.object(forKey: Key.enabled) == nil { return true }
            return defaults.bool(forKey: Key.enabled)
        }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    var activationMode: ActivationMode {
        get {
            let raw = defaults.string(forKey: Key.activationMode) ?? ActivationMode.hover.rawValue
            return ActivationMode(rawValue: raw) ?? .hover
        }
        set { defaults.set(newValue.rawValue, forKey: Key.activationMode) }
    }

    var hoverDelay: TimeInterval {
        get {
            if defaults.object(forKey: Key.hoverDelay) == nil { return 0.22 }
            return max(0.0, min(1.5, defaults.double(forKey: Key.hoverDelay)))
        }
        set { defaults.set(max(0.0, min(1.5, newValue)), forKey: Key.hoverDelay) }
    }

    var iconSize: CGFloat {
        get {
            if defaults.object(forKey: Key.iconSize) == nil { return 34 }
            return CGFloat(max(24.0, min(56.0, defaults.double(forKey: Key.iconSize))))
        }
        set { defaults.set(Double(max(24, min(56, newValue))), forKey: Key.iconSize) }
    }

    /// Zero means the icon remains visible until another action dismisses it.
    var autoHideDelay: TimeInterval {
        get {
            if defaults.object(forKey: Key.autoHideDelay) == nil { return 5.0 }
            return max(0.0, min(30.0, defaults.double(forKey: Key.autoHideDelay)))
        }
        set { defaults.set(max(0.0, min(30.0, newValue)), forKey: Key.autoHideDelay) }
    }

    var panelPosition: PanelPosition {
        get {
            let raw = defaults.string(forKey: Key.panelPosition) ?? PanelPosition.belowRight.rawValue
            return PanelPosition(rawValue: raw) ?? .belowRight
        }
        set { defaults.set(newValue.rawValue, forKey: Key.panelPosition) }
    }

    var inputBoxState: InputBoxState {
        get {
            let raw = defaults.string(forKey: Key.inputBoxState) ?? InputBoxState.alwaysUnfold.rawValue
            return InputBoxState(rawValue: raw) ?? .alwaysUnfold
        }
        set { defaults.set(newValue.rawValue, forKey: Key.inputBoxState) }
    }

    var copyFallbackEnabled: Bool {
        get {
            if defaults.object(forKey: Key.copyFallback) == nil { return true }
            return defaults.bool(forKey: Key.copyFallback)
        }
        set { defaults.set(newValue, forKey: Key.copyFallback) }
    }

    var didShowWelcome: Bool {
        get { defaults.bool(forKey: Key.didShowWelcome) }
        set { defaults.set(newValue, forKey: Key.didShowWelcome) }
    }

    var didConfigureBobAutoLaunch: Bool {
        get { defaults.bool(forKey: Key.didConfigureBobAutoLaunch) }
        set { defaults.set(newValue, forKey: Key.didConfigureBobAutoLaunch) }
    }

    var appFilterMode: AppFilterMode {
        get {
            let raw = defaults.string(forKey: Key.appFilterMode) ?? AppFilterMode.allowAll.rawValue
            return AppFilterMode(rawValue: raw) ?? .allowAll
        }
        set { defaults.set(newValue.rawValue, forKey: Key.appFilterMode) }
    }

    var whitelistedApps: Set<String> {
        get {
            let array = defaults.array(forKey: Key.whitelistedApps) as? [String] ?? []
            return Set(array)
        }
        set { defaults.set(Array(newValue).sorted(), forKey: Key.whitelistedApps) }
    }

    var blacklistedApps: Set<String> {
        get {
            let array = defaults.array(forKey: Key.blacklistedApps) as? [String] ?? []
            return Set(array)
        }
        set { defaults.set(Array(newValue).sorted(), forKey: Key.blacklistedApps) }
    }

    func addToWhitelist(_ bundleID: String) {
        var apps = whitelistedApps
        apps.insert(bundleID)
        whitelistedApps = apps
    }

    func removeFromWhitelist(_ bundleID: String) {
        var apps = whitelistedApps
        apps.remove(bundleID)
        whitelistedApps = apps
    }

    func addToBlacklist(_ bundleID: String) {
        var apps = blacklistedApps
        apps.insert(bundleID)
        blacklistedApps = apps
    }

    func removeFromBlacklist(_ bundleID: String) {
        var apps = blacklistedApps
        apps.remove(bundleID)
        blacklistedApps = apps
    }
}
