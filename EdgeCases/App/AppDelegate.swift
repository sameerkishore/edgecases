import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let edges = EdgeController()
    private var guideWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        edges.start()
        if let index = CommandLine.arguments.firstIndex(of: "-snapshot"), index + 1 < CommandLine.arguments.count {
            Snapshot.render(edges: edges, to: URL(filePath: CommandLine.arguments[index + 1]))
            exit(0)
        }
        if !edges.preferences.hasSeenSetupGuide || !edges.isTrusted {
            showSetupGuide()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Never leave the pointer detached from the trackpad.
        edges.stop()
    }

    func showSetupGuide() {
        if guideWindow == nil {
            let window = NSWindow(
                contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered, defer: false
            )
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: SetupGuideView(edges: edges) { [weak self] in
                self?.edges.preferences.hasSeenSetupGuide = true
                self?.guideWindow?.close()
            })
            window.center()
            guideWindow = window
        }
        NSApp.activate()
        guideWindow?.makeKeyAndOrderFront(nil)
    }
}
