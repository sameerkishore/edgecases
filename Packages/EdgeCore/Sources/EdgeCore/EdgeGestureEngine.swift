/// One finger on the trackpad in a single frame, in normalized coordinates.
public struct Contact: Sendable, Equatable {
    /// Stable for as long as the finger stays down.
    public var id: Int
    /// 0 at the left edge, 1 at the right.
    public var x: Double
    /// 0 at the bottom edge, 1 at the top.
    public var y: Double

    public init(id: Int, x: Double, y: Double) {
        self.id = id
        self.x = x
        self.y = y
    }
}

public enum Edge: Sendable, Equatable {
    case left, right
}

public enum EdgeEvent: Sendable, Equatable {
    /// A finger came down on an edge. It may still turn out to be ordinary pointing.
    case touched(Edge)
    /// The touch moved sideways first, so it's ordinary pointing after all.
    case cancelled(Edge)
    /// The finger moved along the edge far enough to count as a slide.
    case began(Edge)
    /// Whole steps moved since the last one: positive is up, negative is down.
    case step(Edge, Int)
    /// The finger lifted, or another finger joined.
    case ended(Edge)
}

public struct EdgeConfig: Sendable, Equatable {
    /// How far in from each side a touch must start to count as on the edge.
    public var edgeWidth = 0.07
    /// Travel along the edge before a touch becomes a slide.
    public var activationDistance = 0.02
    /// Travel along the edge per step.
    public var stepDistance = 0.045

    public init() {}
}

/// Turns trackpad frames into edge slides. Feed it every frame; it holds no timers.
public struct EdgeGestureEngine: Sendable {
    private enum Phase: Equatable {
        case idle
        /// Down on an edge, not yet moved enough to tell a slide from pointing.
        case candidate(id: Int, edge: Edge, startX: Double, startY: Double)
        case sliding(id: Int, edge: Edge, anchorY: Double)
        /// A touch that isn't ours; wait until every finger lifts.
        case ignoring
    }

    public var config: EdgeConfig
    private var phase = Phase.idle

    public init(config: EdgeConfig = EdgeConfig()) {
        self.config = config
    }

    public var isSliding: Bool {
        if case .sliding = phase { true } else { false }
    }

    /// Ends any slide in progress, as when the app is paused mid-slide.
    public mutating func reset() -> [EdgeEvent] {
        defer { phase = .idle }
        switch phase {
        case .sliding(_, let edge, _): return [.ended(edge)]
        case .candidate(_, let edge, _, _): return [.cancelled(edge)]
        case .idle, .ignoring: return []
        }
    }

    /// `contacts` are the fingers touching the surface in this frame.
    public mutating func process(_ contacts: [Contact]) -> [EdgeEvent] {
        switch phase {
        case .idle:
            guard let finger = contacts.first else { return [] }
            guard contacts.count == 1, let edge = edge(at: finger.x) else {
                phase = .ignoring
                return []
            }
            phase = .candidate(id: finger.id, edge: edge, startX: finger.x, startY: finger.y)
            return [.touched(edge)]

        case .candidate(let id, let edge, let startX, let startY):
            guard contacts.count == 1, let finger = contacts.first, finger.id == id else {
                phase = contacts.isEmpty ? .idle : .ignoring
                return [.cancelled(edge)]
            }
            let dx = abs(finger.x - startX)
            let dy = abs(finger.y - startY)
            if dx >= config.activationDistance && dx > dy {
                phase = .ignoring
                return [.cancelled(edge)]
            }
            if dy >= config.activationDistance {
                phase = .sliding(id: id, edge: edge, anchorY: finger.y)
                return [.began(edge)]
            }
            return []

        case .sliding(let id, let edge, let anchorY):
            guard contacts.count == 1, let finger = contacts.first, finger.id == id else {
                phase = contacts.isEmpty ? .idle : .ignoring
                return [.ended(edge)]
            }
            let steps = Int((finger.y - anchorY) / config.stepDistance)
            guard steps != 0 else { return [] }
            phase = .sliding(id: id, edge: edge, anchorY: anchorY + Double(steps) * config.stepDistance)
            return [.step(edge, steps)]

        case .ignoring:
            if contacts.isEmpty { phase = .idle }
            return []
        }
    }

    private func edge(at x: Double) -> Edge? {
        if x <= config.edgeWidth { return .left }
        if x >= 1 - config.edgeWidth { return .right }
        return nil
    }
}
