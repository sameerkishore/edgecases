import AppKit
import EdgeCore

/// The menu bar icon and its menu, rebuilt each time it opens. A SwiftUI panel replaces this in phase 3.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let edges: EdgeController
    private let trackpadFound: Bool
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var preferences: Preferences { edges.preferences }

    init(edges: EdgeController, trackpadFound: Bool) {
        self.edges = edges
        self.trackpadFound = trackpadFound
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.and.hand.point.up.left", accessibilityDescription: "EdgeCases")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let trusted = Accessibility.isTrusted
        if trusted { edges.installInputTap() }
        let prefs = preferences
        menu.removeAllItems()

        menu.addItem(header(statusLine(trusted: trusted)))
        if !trusted {
            menu.addItem(ActionItem("Grant Accessibility Access…") {
                Accessibility.requestIfNeeded()
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            })
        }
        menu.addItem(.separator())
        menu.addItem(toggle("Enabled", prefs.enabled) { prefs.enabled.toggle() })
        menu.addItem(submenu("Haptic Feedback", HapticStrength.allCases.map { strength in
            toggle(strength.title, prefs.hapticStrength == strength) {
                prefs.hapticStrength = strength
                Haptics.tick(strength)
            }
        }))
        menu.addItem(toggle("Quick Mute", prefs.quickMute, detail: "Double-tap the top-right corner") { prefs.quickMute.toggle() })
        menu.addItem(toggle("Media Strip", prefs.mediaStrip, detail: "Slide along the bottom edge to skip") { prefs.mediaStrip.toggle() })
        menu.addItem(toggle("Tap to Play or Pause", prefs.tapToPlay, detail: "Tap the bottom edge") { prefs.tapToPlay.toggle() })

        menu.addItem(.separator())
        menu.addItem(header("Edges"))
        menu.addItem(toggle("Swap Sides", prefs.swapSides, detail: "Brightness on the right") { prefs.swapSides.toggle() })
        menu.addItem(toggle("Bottom Quarter Only", prefs.bottomQuarterOnly, detail: "Ignore side touches higher up") { prefs.bottomQuarterOnly.toggle() })
        menu.addItem(toggle("Require Fn or ⌥", prefs.requireModifier, detail: "Only slide while holding one") { prefs.requireModifier.toggle() })
        menu.addItem(toggle("Freeze Cursor", prefs.freezeCursor, detail: "Pointer stays put while sliding") { prefs.freezeCursor.toggle() })
        menu.addItem(toggle("Fine Control", prefs.fineControl, detail: "Hold ⇧⌥ for quarter steps") { prefs.fineControl.toggle() })
        menu.addItem(submenu("Sensitivity", [0.5, 0.75, 1, 1.5, 2].map { value in
            toggle(value.formatted() + "×", prefs.sensitivity == value) { prefs.sensitivity = value }
        }))
        menu.addItem(submenu("Edge Width", [0.04, 0.05, 0.07, 0.1, 0.12].map { value in
            toggle(value.formatted(.percent), prefs.edgeWidth == value) { prefs.edgeWidth = value }
        }))

        menu.addItem(.separator())
        menu.addItem(submenu("Debug", debugItems()))
        menu.addItem(ActionItem("Quit EdgeCases", key: "q") { NSApp.terminate(nil) })
    }

    private func statusLine(trusted: Bool) -> String {
        if !trackpadFound { return "No built-in trackpad found" }
        if !trusted { return "Needs Accessibility access" }
        if !preferences.enabled { return "Paused" }
        return preferences.swapSides ? "Left: volume · Right: brightness" : "Left: brightness · Right: volume"
    }

    private func debugItems() -> [NSMenuItem] {
        let monitor = edges.monitor
        let recording: NSMenuItem = if monitor.isRecording {
            ActionItem("Stop Recording and Save") { [weak self] in self?.saveRecording() }
        } else {
            ActionItem("Record Touches") { monitor.startRecording() }
        }
        return [
            recording,
            ActionItem("Show Recordings") { NSWorkspace.shared.open(Self.tracesFolder) },
            .separator(),
            submenu("Play Haptic Waveform", (1...16).map { id in
                ActionItem("Waveform \(id)") { Haptics.play(Int32(id)) }
            }),
        ]
    }

    private static var tracesFolder: URL {
        URL.applicationSupportDirectory.appending(path: "EdgeCases/Traces", directoryHint: .isDirectory)
    }

    private func saveRecording() {
        guard let trace = edges.monitor.stopRecording() else { return }
        let folder = Self.tracesFolder
        let stamp = Date().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false)
            .dateSeparator(.omitted).timeSeparator(.omitted).dateTimeSeparator(.standard))
        let file = folder.appending(path: "trace-\(stamp).json")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try JSONEncoder().encode(trace).write(to: file)
            Log.touch.notice("Saved \(trace.frames.count) frames to \(file.path, privacy: .public)")
            NSWorkspace.shared.activateFileViewerSelecting([file])
        } catch {
            Log.touch.error("Couldn't save recording: \(error)")
        }
    }

    // MARK: Item helpers

    private func header(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func toggle(_ title: String, _ isOn: Bool, detail: String? = nil, action: @escaping () -> Void) -> NSMenuItem {
        let item = ActionItem(title, action: action)
        item.state = isOn ? .on : .off
        if let detail { item.toolTip = detail }
        return item
    }

    private func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu()
        items.forEach(menu.addItem)
        item.submenu = menu
        return item
    }
}

/// A menu item that runs a closure.
private final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", action: @escaping () -> Void) {
        handler = action
        super.init(title: title, action: #selector(run), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not used") }

    @objc private func run() { handler() }
}
