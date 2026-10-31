/// A recording of real trackpad use, for tuning the engine against what fingers and palms actually do.
public struct Trace: Sendable, Equatable, Codable {
    public struct Frame: Sendable, Equatable, Codable {
        public var time: Double
        public var contacts: [Contact]
        public var modifierHeld: Bool

        public init(time: Double, contacts: [Contact], modifierHeld: Bool = false) {
            self.time = time
            self.contacts = contacts
            self.modifierHeld = modifierHeld
        }
    }

    public var frames: [Frame] = []
    public var keyPresses: [Double] = []
    public var clicks: [Double] = []

    public init(frames: [Frame] = [], keyPresses: [Double] = [], clicks: [Double] = []) {
        self.frames = frames
        self.keyPresses = keyPresses
        self.clicks = clicks
    }

    /// Plays the trace through a fresh engine, with key presses and clicks interleaved by time.
    public func replay(config: EdgeConfig = EdgeConfig()) -> [EdgeEvent] {
        var engine = EdgeGestureEngine(config: config)
        var keys = keyPresses.sorted()[...]
        var clicks = clicks.sorted()[...]
        var events: [EdgeEvent] = []
        for frame in frames {
            while let key = keys.first, key <= frame.time {
                engine.lastKeyPress = key
                keys.removeFirst()
            }
            while let click = clicks.first, click <= frame.time {
                events += engine.clicked()
                clicks.removeFirst()
            }
            events += engine.process(frame.contacts, at: frame.time, modifierHeld: frame.modifierHeld)
        }
        return events
    }
}
