import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let edges = EdgeController()
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let trackpadFound = edges.start()
        menuBar = MenuBarController(edges: edges, trackpadFound: trackpadFound)
        Accessibility.requestIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Never leave the pointer detached from the trackpad.
        edges.stop()
    }
}
