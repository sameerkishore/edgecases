import CoreGraphics

/// Keeps the pointer still while a finger slides along an edge.
@MainActor
final class CursorLock {
    private var anchor: CGPoint?
    private var isLocked = false

    /// Call when a finger lands on an edge, before we know it's a slide.
    func remember() {
        anchor = CGEvent(source: nil)?.location
    }

    /// Undo the drift from before the slide was recognised, then stop the pointer following the trackpad.
    func lock() {
        if let anchor { CGWarpMouseCursorPosition(anchor) }
        CGAssociateMouseAndMouseCursorPosition(0)
        isLocked = true
    }

    func unlock() {
        anchor = nil
        guard isLocked else { return }
        CGAssociateMouseAndMouseCursorPosition(1)
        isLocked = false
    }
}
