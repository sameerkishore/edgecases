import AppKit
import EdgeCore

/// Turns edge gestures into actions: brightness and volume on the sides, tracks on the bottom,
/// mute in the top-right corner.
@MainActor
final class EdgeController {
    let preferences = Preferences()
    private let cursor = CursorLock()
    private(set) lazy var monitor = TrackpadMonitor { [weak self] event in
        self?.handle(event)
    }
    private lazy var inputTap = InputTap(monitor: monitor)

    init() {
        preferences.onChange = { [weak self] in self?.apply() }
    }

    @discardableResult
    func start() -> Bool {
        apply()
        installInputTap()
        return monitor.start()
    }

    func stop() {
        monitor.stop()
        cursor.unlock()
    }

    /// Key presses and clicks need Accessibility; try again once it's granted.
    @discardableResult
    func installInputTap() -> Bool {
        inputTap.install()
    }

    private func apply() {
        monitor.isEnabled = preferences.enabled
        monitor.config = preferences.config
    }

    private func handle(_ event: EdgeEvent) {
        switch event {
        case .touched:
            cursor.remember()
        case .cancelled:
            cursor.unlock()
        case .began(let edge):
            Log.action.info("Slide began on \(String(describing: edge), privacy: .public)")
            if preferences.freezeCursor { cursor.lock() }
        case .step(let edge, let count):
            let key = key(for: edge, up: count > 0)
            let modifiers = fineModifiers(for: edge)
            Log.action.info("Step \(count) on \(String(describing: edge), privacy: .public): \(String(describing: key), privacy: .public), trusted \(Accessibility.isTrusted)")
            for _ in 0..<abs(count) { key.press(modifiers: modifiers) }
            Haptics.tick(preferences.hapticStrength)
        case .ended(let edge):
            Log.action.info("Slide ended on \(String(describing: edge), privacy: .public)")
            cursor.unlock()
        case .tapped:
            Log.action.info("Bottom edge tapped: play/pause")
            MediaKey.play.press()
            Haptics.tick(preferences.hapticStrength)
        case .doubleTapped:
            Log.action.info("Corner double-tapped: mute")
            MediaKey.mute.press()
            Haptics.tick(preferences.hapticStrength)
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
