import CoreGraphics
import os

/// Watches key presses and clicks system-wide, so the engine can tell typing palms and physical
/// clicks from edge gestures, and swallow tap-to-click's click after an edge tap.
/// Needs Accessibility access; `install()` fails until it's granted.
@MainActor
final class InputTap {
    private let monitor: TrackpadMonitor
    private var tap: CFMachPort?

    init(monitor: TrackpadMonitor) {
        self.monitor = monitor
    }

    var isInstalled: Bool { tap != nil }

    @discardableResult
    func install() -> Bool {
        guard tap == nil else { return true }
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: inputTapCallback,
            userInfo: Unmanaged.passUnretained(monitor).toOpaque()
        ) else {
            Log.touch.notice("Input tap unavailable (needs Accessibility)")
            return false
        }
        let source = CFMachPortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        tap = port
        tapPort = port
        Log.touch.notice("Input tap installed")
        return true
    }
}

/// For re-enabling the tap from the callback after the system disables it for being slow.
nonisolated(unsafe) private var tapPort: CFMachPort?

private func inputTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<TrackpadMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        if let tapPort { CGEvent.tapEnable(tap: tapPort, enable: true) }
    case .keyDown:
        monitor.keyPressed()
    case .leftMouseDown:
        if !monitor.mouseDown() {
            Log.touch.info("Swallowed tap-to-click after an edge tap")
            return nil
        }
    case .leftMouseUp:
        if !monitor.mouseUp() { return nil }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}
