import CoreGraphics
import os

/// Keeps the pointer still while a finger slides along an edge.
@MainActor
final class CursorLock {
    /// Where the pointer is pinned while frozen. The input tap reads it to drop pointer movement:
    /// macOS ignores `CGAssociateMouseAndMouseCursorPosition` from a background app like this one.
    nonisolated static let frozenAt = OSAllocatedUnfairLock<CGPoint?>(initialState: nil)

    private var anchor: CGPoint?
    private var isLocked = false

    /// Call when a finger lands on an edge, before we know it's a slide.
    func remember() {
        anchor = CGEvent(source: nil)?.location
    }

    /// Undo the drift from before the slide was recognised, then keep the pointer there.
    func lock() {
        guard let point = anchor ?? CGEvent(source: nil)?.location else { return }
        CGWarpMouseCursorPosition(point)
        CGAssociateMouseAndMouseCursorPosition(0)
        Self.frozenAt.withLock { $0 = point }
        isLocked = true
    }

    func unlock() {
        anchor = nil
        guard isLocked else { return }
        Self.frozenAt.withLock { $0 = nil }
        CGAssociateMouseAndMouseCursorPosition(1)
        isLocked = false
    }
}
