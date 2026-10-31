import AppKit
import EdgeCore

/// Turns edge slides into actions: brightness on the left, volume on the right.
@MainActor
final class EdgeController {
    private let cursor = CursorLock()
    private lazy var monitor = TrackpadMonitor { [weak self] event in
        self?.handle(event)
    }

    @discardableResult
    func start() -> Bool {
        monitor.start()
    }

    func stop() {
        monitor.stop()
        cursor.unlock()
    }

    var isEnabled: Bool {
        get { monitor.isEnabled }
        set { monitor.isEnabled = newValue }
    }

    private func handle(_ event: EdgeEvent) {
        switch event {
        case .touched:
            cursor.remember()
        case .cancelled:
            cursor.unlock()
        case .began(let edge):
            Log.action.info("Slide began on \(String(describing: edge))")
            cursor.lock()
        case .step(let edge, let count):
            let key: MediaKey = switch edge {
            case .left: count > 0 ? .brightnessUp : .brightnessDown
            case .right: count > 0 ? .soundUp : .soundDown
            }
            for _ in 0..<abs(count) { key.press() }
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        case .ended(let edge):
            Log.action.info("Slide ended on \(String(describing: edge))")
            cursor.unlock()
        }
    }
}
