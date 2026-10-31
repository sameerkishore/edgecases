import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let edges = EdgeController()
    private var menuBar: MenuBarController?
    private var trustTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let trackpadFound = edges.start()
        menuBar = MenuBarController(edges: edges, trackpadFound: trackpadFound)
        if !Accessibility.requestIfNeeded() {
            waitForAccessibility()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Never leave the pointer detached from the trackpad.
        edges.stop()
    }

    /// Picks up the grant as soon as it's given in System Settings, without a relaunch.
    private func waitForAccessibility() {
        Log.action.notice("Waiting for Accessibility access")
        trustTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, Accessibility.isTrusted else { return }
                Log.action.notice("Accessibility access granted")
                self.trustTimer?.invalidate()
                self.trustTimer = nil
                self.edges.installInputTap()
            }
        }
    }
}
