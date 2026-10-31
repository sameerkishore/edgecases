import AppKit

/// The menu bar icon and its menu. A SwiftUI panel replaces this in phase 3.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let edges: EdgeController
    private let trackpadFound: Bool
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let statusLine = NSMenuItem()
    private let grantItem = NSMenuItem()
    private let enabledItem = NSMenuItem()

    init(edges: EdgeController, trackpadFound: Bool) {
        self.edges = edges
        self.trackpadFound = trackpadFound
        super.init()

        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.and.hand.point.up.left", accessibilityDescription: "EdgeCases")

        let menu = NSMenu()
        menu.delegate = self
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(item(grantItem, "Grant Accessibility Access…", #selector(grantAccess)))
        menu.addItem(.separator())
        menu.addItem(item(enabledItem, "Enabled", #selector(toggleEnabled)))
        menu.addItem(.separator())
        menu.addItem(item(NSMenuItem(), "Quit EdgeCases", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp))
        statusItem.menu = menu
        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    private func refresh() {
        let trusted = Accessibility.isTrusted
        statusLine.title = if !trackpadFound {
            "No built-in trackpad found"
        } else if !trusted {
            "Needs Accessibility access"
        } else if edges.isEnabled {
            "Left edge: brightness · Right edge: volume"
        } else {
            "Paused"
        }
        grantItem.isHidden = trusted
        enabledItem.state = edges.isEnabled ? .on : .off
    }

    @objc private func grantAccess() {
        Accessibility.requestIfNeeded()
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func toggleEnabled() {
        edges.isEnabled.toggle()
        refresh()
    }

    private func item(_ item: NSMenuItem, _ title: String, _ action: Selector, key: String = "", target: AnyObject? = nil) -> NSMenuItem {
        item.title = title
        item.action = action
        item.keyEquivalent = key
        item.target = target ?? self
        return item
    }
}
