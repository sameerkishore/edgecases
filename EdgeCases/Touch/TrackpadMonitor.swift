import AppKit
import EdgeCore
import os

/// Streams built-in trackpad frames through the gesture engine and hands edge events to the main actor.
final class TrackpadMonitor: @unchecked Sendable {
    /// The C callback can't capture context, so it reaches the monitor through this.
    nonisolated(unsafe) fileprivate static var current: TrackpadMonitor?

    private let onEvent: @MainActor (EdgeEvent) -> Void
    /// Only touched on the framework's callback thread.
    private var engine = EdgeGestureEngine()
    private let enabled = OSAllocatedUnfairLock(initialState: true)
    private var wakeObserver: NSObjectProtocol?

    init(onEvent: @escaping @MainActor (EdgeEvent) -> Void) {
        self.onEvent = onEvent
    }

    /// Returns false if no trackpad could be started.
    @discardableResult
    func start() -> Bool {
        Self.current = self
        let started = ECMultitouchStart(frameCallback)
        Log.touch.notice("Multitouch started \(started) device(s)")
        if wakeObserver == nil {
            // The framework stops sending frames after sleep until the devices are started again.
            wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
            ) { [weak self] _ in
                self?.start()
            }
        }
        return started > 0
    }

    func stop() {
        ECMultitouchStop()
    }

    var isEnabled: Bool {
        get { enabled.withLock { $0 } }
        set { enabled.withLock { $0 = newValue } }
    }

    fileprivate func handle(_ touches: UnsafeBufferPointer<MTTouch>) {
        let events: [EdgeEvent]
        if isEnabled {
            let contacts = touches.compactMap { touch -> Contact? in
                guard touch.state == MTTouchStateMakeTouch || touch.state == MTTouchStateTouching else { return nil }
                return Contact(id: Int(touch.identifier), x: Double(touch.normalized.position.x), y: Double(touch.normalized.position.y))
            }
            events = engine.process(contacts)
        } else {
            events = engine.reset()
        }
        guard !events.isEmpty else { return }
        let onEvent = onEvent
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                events.forEach(onEvent)
            }
        }
    }
}

private let frameCallback: MTFrameCallback = { _, touches, count, _, _ in
    guard let monitor = TrackpadMonitor.current else { return }
    monitor.handle(UnsafeBufferPointer(start: touches, count: touches == nil ? 0 : count))
}
