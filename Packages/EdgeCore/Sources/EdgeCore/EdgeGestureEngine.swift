/// One finger on the trackpad in a single frame, in normalized coordinates.
public struct Contact: Sendable, Equatable, Codable {
    /// Stable for as long as the finger stays down.
    public var id: Int
    /// 0 at the left edge, 1 at the right.
    public var x: Double
    /// 0 at the bottom edge, 1 at the top.
    public var y: Double
    /// Contact area as the trackpad reports it; palms and thumbs read larger than fingertips.
    public var size: Double

    public init(id: Int, x: Double, y: Double, size: Double = 0) {
        self.id = id
        self.x = x
        self.y = y
        self.size = size
    }
}

public enum Edge: Sendable, Equatable {
    case left, right, bottom
}

public enum Corner: Sendable, Equatable {
    case topRight
}

public enum EdgeEvent: Sendable, Equatable {
    /// A finger came down somewhere we listen. It may still turn out to be ordinary pointing.
    case touched
    /// It turned out to be pointing, a click, or a palm.
    case cancelled
    /// The finger moved along an edge far enough to count as a slide.
    case began(Edge)
    /// Whole steps since the last one: up or right is positive. The bottom edge steps once per slide.
    case step(Edge, Int)
    /// The finger lifted, or another finger joined.
    case ended(Edge)
    /// A quick touch and lift on the bottom edge, without a click.
    case tapped(Edge)
    case doubleTapped(Corner)
}

public struct EdgeConfig: Sendable, Equatable {
    // Choices
    /// How far in from each side a touch must start to count as on the edge.
    public var edgeWidth = 0.07
    /// Steps per distance travelled; 2 means twice as many steps.
    public var sensitivity = 1.0
    /// Side slides only start in the lowest 25% of the trackpad.
    public var bottomQuarterOnly = false
    /// Side slides only start while Fn or ⌥ is held.
    public var requireModifier = false
    /// Slide along the bottom edge to skip tracks.
    public var mediaStrip = true
    /// Tap the bottom edge to play or pause.
    public var tapToPlay = false
    /// Double-tap the top-right corner to mute.
    public var quickMute = true

    // Tuning
    /// Travel before a touch becomes a slide.
    public var activationDistance = 0.02
    /// Travel along a side edge per step, at sensitivity 1.
    public var stepDistance = 0.045
    /// Travel along the bottom edge to skip a track.
    public var swipeDistance = 0.12
    /// Height of the bottom edge, and size of the corner.
    public var bottomHeight = 0.07
    public var cornerSize = 0.12
    /// A touch that rests this long without sliding is a resting finger or palm.
    public var activationWindow = 0.6
    /// Touches that start this soon after a key press are hands on the keyboard.
    public var typingGrace = 0.5
    /// Longest touch that still counts as a tap, and longest gap between double-tap taps.
    public var tapDuration = 0.25
    public var doubleTapInterval = 0.4

    public init() {}
}

/// Turns trackpad frames into edge gestures. Feed it every frame, with the frame's time in seconds.
public struct EdgeGestureEngine: Sendable {
    /// Where a touch started, and so which gestures it can still become.
    private struct Origin: Equatable {
        var id: Int
        var x: Double
        var y: Double
        var time: Double
        var side: Edge?
        var bottom: Bool
        var corner: Corner?
    }

    private enum Phase: Equatable {
        case idle
        /// Down where we listen, not yet moved enough to tell what it is.
        case candidate(Origin)
        case sliding(id: Int, edge: Edge, anchor: Double, stepped: Bool)
        /// A touch that isn't ours; wait until every finger lifts.
        case ignoring
    }

    public var config: EdgeConfig
    /// Time of the last key press, on the same clock as frames.
    public var lastKeyPress: Double?
    private var phase = Phase.idle
    private var lastCornerTap: Double?

    public init(config: EdgeConfig = EdgeConfig()) {
        self.config = config
    }

    public var isSliding: Bool {
        if case .sliding = phase { true } else { false }
    }

    /// True while a touch that could still become a tap is down; a click now means it isn't one.
    public var isTapCandidate: Bool {
        guard case .candidate(let origin) = phase else { return false }
        return origin.corner != nil || (origin.bottom && config.tapToPlay)
    }

    /// Ends any gesture in progress, as when the app is paused mid-slide.
    public mutating func reset() -> [EdgeEvent] {
        defer { phase = .idle }
        switch phase {
        case .sliding(_, let edge, _, _): return [.ended(edge)]
        case .candidate: return [.cancelled]
        case .idle, .ignoring: return []
        }
    }

    /// A physical click during the touch: it's a press, not a tap or a slide.
    public mutating func clicked() -> [EdgeEvent] {
        guard case .candidate = phase else { return [] }
        phase = .ignoring
        return [.cancelled]
    }

    /// `contacts` are the fingers touching the surface in this frame.
    /// `modifierHeld` is whether Fn or ⌥ is down, for `requireModifier`.
    public mutating func process(_ contacts: [Contact], at time: Double, modifierHeld: Bool = false) -> [EdgeEvent] {
        switch phase {
        case .idle:
            guard let finger = contacts.first else { return [] }
            guard contacts.count == 1, !isTyping(at: time),
                  let origin = origin(of: finger, at: time, modifierHeld: modifierHeld) else {
                phase = .ignoring
                return []
            }
            phase = .candidate(origin)
            return [.touched]

        case .candidate(let origin):
            guard contacts.count == 1, let finger = contacts.first, finger.id == origin.id else {
                if contacts.isEmpty {
                    phase = .idle
                    return [.cancelled] + tap(origin, at: time)
                }
                phase = .ignoring
                return [.cancelled]
            }
            if time - origin.time > config.activationWindow || (lastKeyPress ?? -.infinity) > origin.time {
                phase = .ignoring
                return [.cancelled]
            }
            let dx = abs(finger.x - origin.x)
            let dy = abs(finger.y - origin.y)
            if let side = origin.side, dy >= config.activationDistance, dy > dx {
                phase = .sliding(id: origin.id, edge: side, anchor: finger.y, stepped: false)
                return [.began(side)]
            }
            if origin.bottom && config.mediaStrip, dx >= config.activationDistance, dx > dy {
                phase = .sliding(id: origin.id, edge: .bottom, anchor: finger.x, stepped: false)
                return [.began(.bottom)]
            }
            if max(dx, dy) >= config.activationDistance {
                phase = .ignoring
                return [.cancelled]
            }
            return []

        case .sliding(let id, let edge, let anchor, let stepped):
            guard contacts.count == 1, let finger = contacts.first, finger.id == id else {
                phase = contacts.isEmpty ? .idle : .ignoring
                return [.ended(edge)]
            }
            if edge == .bottom {
                guard !stepped, abs(finger.x - anchor) >= config.swipeDistance else { return [] }
                phase = .sliding(id: id, edge: edge, anchor: anchor, stepped: true)
                return [.step(edge, finger.x > anchor ? 1 : -1)]
            }
            let distance = config.stepDistance / config.sensitivity
            let steps = Int((finger.y - anchor) / distance)
            guard steps != 0 else { return [] }
            phase = .sliding(id: id, edge: edge, anchor: anchor + Double(steps) * distance, stepped: true)
            return [.step(edge, steps)]

        case .ignoring:
            if contacts.isEmpty { phase = .idle }
            return []
        }
    }

    private func isTyping(at time: Double) -> Bool {
        guard let lastKeyPress else { return false }
        return time - lastKeyPress < config.typingGrace
    }

    private func origin(of finger: Contact, at time: Double, modifierHeld: Bool) -> Origin? {
        var side: Edge?
        if !config.requireModifier || modifierHeld, !config.bottomQuarterOnly || finger.y <= 0.25 {
            if finger.x <= config.edgeWidth { side = .left }
            if finger.x >= 1 - config.edgeWidth { side = .right }
        }
        let bottom = (config.mediaStrip || config.tapToPlay) && finger.y <= config.bottomHeight
        let corner: Corner? = config.quickMute && finger.x >= 1 - config.cornerSize && finger.y >= 1 - config.cornerSize
            ? .topRight : nil
        guard side != nil || bottom || corner != nil else { return nil }
        return Origin(id: finger.id, x: finger.x, y: finger.y, time: time, side: side, bottom: bottom, corner: corner)
    }

    /// A lift that ended a candidate: was it a tap?
    private mutating func tap(_ origin: Origin, at time: Double) -> [EdgeEvent] {
        guard time - origin.time <= config.tapDuration else { return [] }
        if let corner = origin.corner {
            if let last = lastCornerTap, time - last <= config.doubleTapInterval {
                lastCornerTap = nil
                return [.doubleTapped(corner)]
            }
            lastCornerTap = time
            return []
        }
        if origin.bottom && config.tapToPlay {
            return [.tapped(.bottom)]
        }
        return []
    }
}
