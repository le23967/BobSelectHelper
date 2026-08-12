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

/// Values are held in memory and written through to UserDefaults.
///
/// Several of these are read from inside global mouse-event handlers, which fire on
/// every drag and scroll tick system-wide. A UserDefaults lookup there costs a
/// dictionary hit plus objc dispatch on each event, so the whole store is loaded once
/// at launch and served from stored properties afterwards.
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
        static let language = "language"
        static let showInDock = "showInDock"
    }

    private let defaults = UserDefaults.standard

    private var cachedIsEnabled: Bool
    private var cachedActivationMode: ActivationMode
    private var cachedHoverDelay: TimeInterval
    private var cachedIconSize: CGFloat
    private var cachedAutoHideDelay: TimeInterval
    private var cachedPanelPosition: PanelPosition
    private var cachedInputBoxState: InputBoxState
    private var cachedCopyFallback: Bool
    private var cachedLanguage: Localization.Language
    private var cachedShowInDock: Bool
    private var cachedAppFilterMode: AppFilterMode
    private var cachedWhitelist: Set<String>
    private var cachedBlacklist: Set<String>

    private init() {
        let defaults = self.defaults

        cachedIsEnabled = defaults.object(forKey: Key.enabled) as? Bool ?? true
        cachedCopyFallback = defaults.object(forKey: Key.copyFallback) as? Bool ?? true
        cachedShowInDock = defaults.object(forKey: Key.showInDock) as? Bool ?? true

        cachedActivationMode = ActivationMode(
            rawValue: defaults.string(forKey: Key.activationMode) ?? ""
        ) ?? .hover

        cachedPanelPosition = PanelPosition(
            rawValue: defaults.string(forKey: Key.panelPosition) ?? ""
        ) ?? .belowRight

        cachedInputBoxState = InputBoxState(
            rawValue: defaults.string(forKey: Key.inputBoxState) ?? ""
        ) ?? .alwaysUnfold

        cachedAppFilterMode = AppFilterMode(
            rawValue: defaults.string(forKey: Key.appFilterMode) ?? ""
        ) ?? .allowAll

        cachedHoverDelay = (defaults.object(forKey: Key.hoverDelay) as? Double)
            .map { Settings.clamp($0, 0.0, 1.5) } ?? 0.22

        cachedIconSize = CGFloat(
            (defaults.object(forKey: Key.iconSize) as? Double)
                .map { Settings.clamp($0, 24.0, 56.0) } ?? 34.0
        )

        cachedAutoHideDelay = (defaults.object(forKey: Key.autoHideDelay) as? Double)
            .map { Settings.clamp($0, 0.0, 30.0) } ?? 5.0

        if let raw = defaults.string(forKey: Key.language),
           let stored = Localization.Language(rawValue: raw) {
            cachedLanguage = stored
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            cachedLanguage = preferred.hasPrefix("zh") ? .chinese : .english
        }

        cachedWhitelist = Set(defaults.array(forKey: Key.whitelistedApps) as? [String] ?? [])
        cachedBlacklist = Set(defaults.array(forKey: Key.blacklistedApps) as? [String] ?? [])
    }

    private static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), high)
    }

    var isEnabled: Bool {
        get { cachedIsEnabled }
        set {
            cachedIsEnabled = newValue
            defaults.set(newValue, forKey: Key.enabled)
        }
    }

    var activationMode: ActivationMode {
        get { cachedActivationMode }
        set {
            cachedActivationMode = newValue
            defaults.set(newValue.rawValue, forKey: Key.activationMode)
        }
    }

    var hoverDelay: TimeInterval {
        get { cachedHoverDelay }
        set {
            let clamped = Settings.clamp(newValue, 0.0, 1.5)
            cachedHoverDelay = clamped
            defaults.set(clamped, forKey: Key.hoverDelay)
        }
    }

    var iconSize: CGFloat {
        get { cachedIconSize }
        set {
            let clamped = Settings.clamp(Double(newValue), 24.0, 56.0)
            cachedIconSize = CGFloat(clamped)
            defaults.set(clamped, forKey: Key.iconSize)
        }
    }

    /// Zero means the icon remains visible until another action dismisses it.
    var autoHideDelay: TimeInterval {
        get { cachedAutoHideDelay }
        set {
            let clamped = Settings.clamp(newValue, 0.0, 30.0)
            cachedAutoHideDelay = clamped
            defaults.set(clamped, forKey: Key.autoHideDelay)
        }
    }

    var panelPosition: PanelPosition {
        get { cachedPanelPosition }
        set {
            cachedPanelPosition = newValue
            defaults.set(newValue.rawValue, forKey: Key.panelPosition)
        }
    }

    var inputBoxState: InputBoxState {
        get { cachedInputBoxState }
        set {
            cachedInputBoxState = newValue
            defaults.set(newValue.rawValue, forKey: Key.inputBoxState)
        }
    }

    var copyFallbackEnabled: Bool {
        get { cachedCopyFallback }
        set {
            cachedCopyFallback = newValue
            defaults.set(newValue, forKey: Key.copyFallback)
        }
    }

    /// Defaults to the system language on first launch, then follows the user's choice.
    var language: Localization.Language {
        get { cachedLanguage }
        set {
            cachedLanguage = newValue
            defaults.set(newValue.rawValue, forKey: Key.language)
        }
    }

    /// When false the app runs as an accessory: menu-bar icon only, no Dock tile.
    var showInDock: Bool {
        get { cachedShowInDock }
        set {
            cachedShowInDock = newValue
            defaults.set(newValue, forKey: Key.showInDock)
        }
    }

    var appFilterMode: AppFilterMode {
        get { cachedAppFilterMode }
        set {
            cachedAppFilterMode = newValue
            defaults.set(newValue.rawValue, forKey: Key.appFilterMode)
        }
    }

    var whitelistedApps: Set<String> {
        get { cachedWhitelist }
        set {
            cachedWhitelist = newValue
            defaults.set(Array(newValue).sorted(), forKey: Key.whitelistedApps)
        }
    }

    var blacklistedApps: Set<String> {
        get { cachedBlacklist }
        set {
            cachedBlacklist = newValue
            defaults.set(Array(newValue).sorted(), forKey: Key.blacklistedApps)
        }
    }

    var didShowWelcome: Bool {
        get { defaults.bool(forKey: Key.didShowWelcome) }
        set { defaults.set(newValue, forKey: Key.didShowWelcome) }
    }

    var didConfigureBobAutoLaunch: Bool {
        get { defaults.bool(forKey: Key.didConfigureBobAutoLaunch) }
        set { defaults.set(newValue, forKey: Key.didConfigureBobAutoLaunch) }
    }

    /// True when the frontmost app is allowed to trigger the helper.
    func allowsApplication(_ bundleID: String) -> Bool {
        switch cachedAppFilterMode {
        case .allowAll:
            return true
        case .whitelist:
            return cachedWhitelist.contains(bundleID)
        case .blacklist:
            return !cachedBlacklist.contains(bundleID)
        }
    }

    func addToWhitelist(_ bundleID: String) {
        whitelistedApps = cachedWhitelist.union([bundleID])
    }

    func removeFromWhitelist(_ bundleID: String) {
        whitelistedApps = cachedWhitelist.subtracting([bundleID])
    }

    func addToBlacklist(_ bundleID: String) {
        blacklistedApps = cachedBlacklist.union([bundleID])
    }

    func removeFromBlacklist(_ bundleID: String) {
        blacklistedApps = cachedBlacklist.subtracting([bundleID])
    }
}
