import AppKit

private enum AppIdentity {
    static let bobBundleIdentifier = "com.hezongyidev.Bob"
    static let helperBundleIdentifier = "com.bryannelson.BobSelectHelper"
}

final class LauncherDelegate: NSObject, NSApplicationDelegate {
    private var launchObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let workspace = NSWorkspace.shared
        launchObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: workspace,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  application.bundleIdentifier == AppIdentity.bobBundleIdentifier
            else {
                return
            }

            self?.openMainHelperIfNeeded()
        }

        if !NSRunningApplication.runningApplications(
            withBundleIdentifier: AppIdentity.bobBundleIdentifier
        ).isEmpty {
            openMainHelperIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(launchObserver)
        }
    }

    private func openMainHelperIfNeeded() {
        guard NSRunningApplication.runningApplications(
            withBundleIdentifier: AppIdentity.helperBundleIdentifier
        ).isEmpty else {
            return
        }

        let helperURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.createsNewApplicationInstance = false

        NSWorkspace.shared.openApplication(
            at: helperURL,
            configuration: configuration
        ) { _, _ in }
    }
}

let app = NSApplication.shared
let delegate = LauncherDelegate()
app.delegate = delegate
app.setActivationPolicy(.prohibited)
app.run()
