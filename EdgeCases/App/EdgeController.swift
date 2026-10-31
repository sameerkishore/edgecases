import AppKit
import EdgeCore
import Observation

/// Turns edge gestures into actions: brightness and volume on the sides, tracks on the bottom,
/// a chosen action on each corner double-tap. Also the state the panel shows.
@Observable
@MainActor
final class EdgeController {
    let preferences: Preferences
    let levels = SystemLevels()
    private(set) var isTrusted = Accessibility.isTrusted
    private(set) var trackpadFound = false
    /// Counts slides, so the setup guide can tell when the first one happens.
    private(set) var slidesSeen = 0
    private(set) var isRecording = false
    /// The corner whose shortcut is being recorded from the next key press.
    private(set) var recordingCorner: Corner?

    @ObservationIgnored private let cursor = CursorLock()
    @ObservationIgnored private var trustTimer: Timer?
    @ObservationIgnored private(set) lazy var monitor = TrackpadMonitor { [weak self] event in
        self?.handle(event)
    }
    @ObservationIgnored private lazy var inputTap = InputTap(monitor: monitor)

    init(preferences: Preferences = Preferences()) {
        self.preferences = preferences
        preferences.onChange = { [weak self] in self?.apply() }
    }

    func start() {
        apply()
        trackpadFound = monitor.start()
        checkAccessibility()
        // Picks up the grant (or its removal) in System Settings without a relaunch.
        trustTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkAccessibility() }
        }
    }

    func stop() {
        monitor.stop()
        cursor.unlock()
    }

    private func checkAccessibility() {
        let trusted = Accessibility.isTrusted
        if trusted != isTrusted {
            isTrusted = trusted
            Log.action.notice("Accessibility access \(trusted ? "granted" : "missing", privacy: .public)")
        }
        // Key presses and clicks need Accessibility; the tap installs once it's granted.
        if trusted { inputTap.install() }
    }

    func apply() {
        monitor.isEnabled = preferences.enabled
        monitor.config = preferences.config
        NSApp?.appearance = preferences.appearance.nsAppearance
    }

    // MARK: Recording

    func startRecording() {
        monitor.startRecording()
        isRecording = true
    }

    /// Saves the trace as JSON and shows it in Finder.
    func stopRecording() {
        isRecording = false
        guard let trace = monitor.stopRecording() else { return }
        let stamp = Date().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false)
            .dateSeparator(.omitted).timeSeparator(.omitted).dateTimeSeparator(.standard))
        let file = Self.tracesFolder.appending(path: "trace-\(stamp).json")
        do {
            try FileManager.default.createDirectory(at: Self.tracesFolder, withIntermediateDirectories: true)
            try JSONEncoder().encode(trace).write(to: file)
            Log.touch.notice("Saved \(trace.frames.count) frames to \(file.path, privacy: .public)")
            NSWorkspace.shared.activateFileViewerSelecting([file])
        } catch {
            Log.touch.error("Couldn't save recording: \(error)")
        }
    }

    static var tracesFolder: URL {
        URL.applicationSupportDirectory.appending(path: "EdgeCases/Traces", directoryHint: .isDirectory)
    }

    // MARK: Corner actions

    /// Captures the next key press as the corner's shortcut. Escape cancels.
    func recordShortcut(for corner: Corner) {
        recordingCorner = corner
        keyCapture = { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, let combo = KeyCombo(event: event) else { return }
                if !combo.isPlainEscape { self.preferences.setAction(.shortcut(combo), for: corner) }
                self.stopRecordingShortcut()
            }
        }
    }

    func stopRecordingShortcut() {
        keyCapture = nil
        recordingCorner = nil
    }

    func chooseApp(for corner: Corner) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(filePath: "/Applications")
        panel.prompt = "Choose"
        panel.message = "Pick an app to open with a \(corner.title.lowercased()) double-tap"
        NSApp.activate()
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            MainActor.assumeIsolated { self?.preferences.setAction(.openApp(path: url.path), for: corner) }
        }
    }

    // MARK: Gestures

    private func handle(_ event: EdgeEvent) {
        switch event {
        case .touched:
            cursor.remember()
        case .cancelled:
            cursor.unlock()
        case .began(let edge):
            Log.action.info("Slide began on \(String(describing: edge), privacy: .public)")
            slidesSeen += 1
            if preferences.freezeCursor { cursor.lock() }
        case .step(let edge, let count):
            let key = key(for: edge, up: count > 0)
            let modifiers = fineModifiers(for: edge)
            Log.action.info("Step \(count) on \(String(describing: edge), privacy: .public): \(String(describing: key), privacy: .public), trusted \(Accessibility.isTrusted)")
            for _ in 0..<abs(count) { key.press(modifiers: modifiers) }
            Haptics.tick(preferences.hapticStrength)
            levels.refreshSoon()
        case .ended(let edge):
            Log.action.info("Slide ended on \(String(describing: edge), privacy: .public)")
            cursor.unlock()
        case .tapped:
            Log.action.info("Bottom edge tapped: play/pause")
            MediaKey.play.press()
            Haptics.tick(preferences.hapticStrength)
        case .doubleTapped(let corner):
            let action = preferences.action(for: corner)
            Log.action.info("\(corner.title, privacy: .public) double-tapped: \(action.summary, privacy: .public)")
            action.perform()
            Haptics.tick(preferences.hapticStrength)
            levels.refreshSoon()
        }
    }

    private func key(for edge: Edge, up: Bool) -> MediaKey {
        let brightness = preferences.swapSides ? Edge.right : .left
        switch edge {
        case .bottom: return up ? .next : .previous
        case brightness: return up ? .brightnessUp : .brightnessDown
        default: return up ? .soundUp : .soundDown
        }
    }

    /// Shift-Option on a brightness or volume key asks macOS for a quarter step.
    private func fineModifiers(for edge: Edge) -> NSEvent.ModifierFlags {
        guard preferences.fineControl, edge != .bottom else { return [] }
        let held = NSEvent.modifierFlags
        return held.contains([.shift, .option]) ? [.shift, .option] : []
    }
}
