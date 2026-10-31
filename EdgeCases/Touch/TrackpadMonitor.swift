import AppKit
import EdgeCore
import os

/// Streams built-in trackpad frames through the gesture engine and hands its events to the main actor.
/// Frames arrive on the framework's own thread; key presses and clicks arrive from `InputTap` on the
/// main thread. Everything they share sits behind `shared`.
final class TrackpadMonitor: @unchecked Sendable {
    /// The C callback can't capture context, so it reaches the monitor through this.
    nonisolated(unsafe) fileprivate static var current: TrackpadMonitor?

    private struct Shared {
        var enabled = true
        var config = EdgeConfig()
        var lastKeyPress: Double?
        var pendingClick = false
        /// After a tap lifts, tap-to-click's click is ours, not the app's under the pointer.
        var swallowClicksUntil = 0.0
        var swallowingMouseUp = false
        var recording: Trace?
    }

    private let shared = OSAllocatedUnfairLock(initialState: Shared())
    private let onEvent: @MainActor (EdgeEvent) -> Void
    /// Only touched on the framework's callback thread.
    private var engine = EdgeGestureEngine()
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
        get { shared.withLock { $0.enabled } }
        set { shared.withLock { $0.enabled = newValue } }
    }

    var config: EdgeConfig {
        get { shared.withLock { $0.config } }
        set { shared.withLock { $0.config = newValue } }
    }

    // MARK: Input from InputTap

    func keyPressed() {
        let now = ProcessInfo.processInfo.systemUptime
        shared.withLock {
            $0.lastKeyPress = now
            $0.recording?.keyPresses.append(now)
        }
    }

    /// Returns false if the click should be swallowed.
    func mouseDown() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        return shared.withLock {
            if now < $0.swallowClicksUntil {
                $0.swallowClicksUntil = 0
                $0.swallowingMouseUp = true
                return false
            }
            $0.pendingClick = true
            $0.recording?.clicks.append(now)
            return true
        }
    }

    /// Returns false if the release should be swallowed.
    func mouseUp() -> Bool {
        shared.withLock {
            defer { $0.swallowingMouseUp = false }
            return !$0.swallowingMouseUp
        }
    }

    // MARK: Recording

    var isRecording: Bool { shared.withLock { $0.recording != nil } }

    func startRecording() {
        shared.withLock { $0.recording = Trace() }
    }

    func stopRecording() -> Trace? {
        shared.withLock {
            defer { $0.recording = nil }
            return $0.recording
        }
    }

    // MARK: Frames

    fileprivate func handle(_ touches: UnsafeBufferPointer<MTTouch>) {
        let now = ProcessInfo.processInfo.systemUptime
        let contacts = touches.compactMap { touch -> Contact? in
            guard touch.state == MTTouchStateMakeTouch || touch.state == MTTouchStateTouching else { return nil }
            return Contact(
                id: Int(touch.identifier),
                x: Double(touch.normalized.position.x),
                y: Double(touch.normalized.position.y),
                size: Double(touch.size)
            )
        }
        let flags = CGEventSource.flagsState(.combinedSessionState)
        let modifierHeld = !flags.isDisjoint(with: [.maskSecondaryFn, .maskAlternate])

        let state = shared.withLock { state in
            defer { state.pendingClick = false }
            if state.recording != nil, !contacts.isEmpty || state.recording?.frames.last?.contacts.isEmpty == false {
                state.recording?.frames.append(Trace.Frame(time: now, contacts: contacts, modifierHeld: modifierHeld))
            }
            return state
        }

        var events: [EdgeEvent] = []
        if state.enabled {
            engine.config = state.config
            engine.lastKeyPress = state.lastKeyPress
            if state.pendingClick { events += engine.clicked() }
            let wasTapCandidate = engine.isTapCandidate
            events += engine.process(contacts, at: now, modifierHeld: modifierHeld)
            if wasTapCandidate && contacts.isEmpty && !engine.isTapCandidate {
                shared.withLock { $0.swallowClicksUntil = now + 0.3 }
            }
        } else {
            events = engine.reset()
        }

        if let single = contacts.first, contacts.count == 1, events.contains(where: { if case .began = $0 { true } else { false } }) {
            Log.touch.info("Slide began at x \(single.x, format: .fixed(precision: 3)) y \(single.y, format: .fixed(precision: 3)) size \(single.size, format: .fixed(precision: 2))")
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
