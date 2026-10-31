import Testing
@testable import EdgeCore

/// One finger along a path of (x, y) points, a frame every 10 ms from `start`, then a lift.
private func path(_ points: [(Double, Double)], start: Double = 0, id: Int = 1) -> [Trace.Frame] {
    let frames = points.enumerated().map { i, point in
        Trace.Frame(time: start + Double(i) * 0.01, contacts: [Contact(id: id, x: point.0, y: point.1)])
    }
    return frames + [Trace.Frame(time: start + Double(points.count) * 0.01, contacts: [])]
}

private func config(_ change: (inout EdgeConfig) -> Void) -> EdgeConfig {
    var config = EdgeConfig()
    change(&config)
    return config
}

// MARK: Side slides

@Test func slideUpTheRightEdgeSteps() {
    let events = Trace(frames: path([(0.97, 0.3), (0.97, 0.33), (0.97, 0.38), (0.96, 0.43)])).replay()
    #expect(events == [.touched, .began(.right), .step(.right, 1), .step(.right, 1), .ended(.right)])
}

@Test func slideDownTheLeftEdgeStepsNegative() {
    let events = Trace(frames: path([(0.02, 0.8), (0.02, 0.77), (0.02, 0.6)])).replay()
    #expect(events == [.touched, .began(.left), .step(.left, -3), .ended(.left)])
}

@Test func sensitivityScalesSteps() {
    let events = Trace(frames: path([(0.02, 0.8), (0.02, 0.77), (0.02, 0.6)])).replay(config: config { $0.sensitivity = 2 })
    #expect(events.contains(.step(.left, -7)))
}

@Test func touchInTheMiddleIsIgnored() {
    #expect(Trace(frames: path([(0.5, 0.5), (0.5, 0.8)])).replay().isEmpty)
}

@Test func movingSidewaysFromTheEdgeIsPointing() {
    let events = Trace(frames: path([(0.98, 0.5), (0.9, 0.51), (0.9, 0.8)])).replay()
    #expect(events == [.touched, .cancelled])
}

@Test func secondFingerEndsTheSlide() {
    var engine = EdgeGestureEngine()
    _ = engine.process([Contact(id: 1, x: 0.98, y: 0.3)], at: 0)
    _ = engine.process([Contact(id: 1, x: 0.98, y: 0.4)], at: 0.01)
    #expect(engine.process([Contact(id: 1, x: 0.98, y: 0.4), Contact(id: 2, x: 0.5, y: 0.5)], at: 0.02) == [.ended(.right)])
    // Nothing restarts until every finger is up.
    #expect(engine.process([Contact(id: 2, x: 0.98, y: 0.5)], at: 0.03).isEmpty)
    #expect(engine.process([], at: 0.04).isEmpty)
    #expect(engine.process([Contact(id: 3, x: 0.98, y: 0.5)], at: 0.05) == [.touched])
}

@Test func resetEndsASlide() {
    var engine = EdgeGestureEngine()
    _ = engine.process([Contact(id: 1, x: 0.02, y: 0.3)], at: 0)
    _ = engine.process([Contact(id: 1, x: 0.02, y: 0.4)], at: 0.01)
    #expect(engine.isSliding)
    #expect(engine.reset() == [.ended(.left)])
    #expect(!engine.isSliding)
}

// MARK: Accidental touches

@Test func touchRightAfterTypingIsIgnored() {
    let trace = Trace(frames: path([(0.02, 0.5), (0.02, 0.55), (0.02, 0.7)], start: 10), keyPresses: [9.8])
    #expect(trace.replay().isEmpty)
}

@Test func touchWellAfterTypingSlides() {
    let trace = Trace(frames: path([(0.02, 0.5), (0.02, 0.55), (0.02, 0.7)], start: 10), keyPresses: [9])
    #expect(trace.replay().contains(.began(.left)))
}

@Test func keyPressDuringTheTouchCancelsIt() {
    let trace = Trace(frames: path([(0.02, 0.5), (0.02, 0.505), (0.02, 0.51), (0.02, 0.6)], start: 10), keyPresses: [10.015])
    #expect(trace.replay() == [.touched, .cancelled])
}

@Test func restingFingerThatDriftsLaterIsIgnored() {
    // A palm on the edge for a second, then creeping upward: never a slide.
    let resting = (0..<100).map { _ in (0.02, 0.5) }
    let trace = Trace(frames: path(resting + [(0.02, 0.55), (0.02, 0.7)]))
    #expect(trace.replay() == [.touched, .cancelled])
}

@Test func bottomQuarterOnlyIgnoresHigherTouches() {
    let only = config { $0.bottomQuarterOnly = true }
    #expect(Trace(frames: path([(0.02, 0.5), (0.02, 0.6)])).replay(config: only).isEmpty)
    #expect(Trace(frames: path([(0.02, 0.15), (0.02, 0.25)])).replay(config: only).contains(.began(.left)))
}

@Test func requireModifier() {
    let required = config { $0.requireModifier = true }
    let plain = Trace(frames: path([(0.02, 0.5), (0.02, 0.6)]))
    #expect(plain.replay(config: required).isEmpty)
    var held = plain
    for i in held.frames.indices { held.frames[i].modifierHeld = true }
    #expect(held.replay(config: required).contains(.began(.left)))
}

// MARK: Bottom edge and corner

@Test func swipeAlongTheBottomSkipsOnce() {
    let events = Trace(frames: path([(0.4, 0.03), (0.43, 0.03), (0.55, 0.03), (0.7, 0.03), (0.9, 0.03)])).replay()
    #expect(events == [.touched, .began(.bottom), .step(.bottom, 1), .ended(.bottom)])
}

@Test func swipeLeftGoesBack() {
    let events = Trace(frames: path([(0.6, 0.03), (0.57, 0.03), (0.4, 0.03)])).replay()
    #expect(events.contains(.step(.bottom, -1)))
}

@Test func mediaStripOff() {
    let off = config { $0.mediaStrip = false }
    #expect(Trace(frames: path([(0.4, 0.03), (0.43, 0.03), (0.6, 0.03)])).replay(config: off).isEmpty)
}

@Test func tapToPlayIsOffByDefault() {
    let tap = Trace(frames: path([(0.5, 0.03), (0.5, 0.03)]))
    #expect(!tap.replay().contains(.tapped(.bottom)))
    #expect(tap.replay(config: config { $0.tapToPlay = true }).contains(.tapped(.bottom)))
}

@Test func clickOnTheBottomEdgeIsNotATap() {
    let trace = Trace(frames: path([(0.5, 0.03), (0.5, 0.03), (0.5, 0.03)]), clicks: [0.015])
    #expect(!trace.replay(config: config { $0.tapToPlay = true }).contains(.tapped(.bottom)))
}

@Test func doubleTapTheCornerMutes() {
    let frames = path([(0.95, 0.95), (0.95, 0.95)]) + path([(0.95, 0.95), (0.95, 0.95)], start: 0.2)
    #expect(Trace(frames: frames).replay().last == .doubleTapped(.topRight))
}

@Test func slowSecondTapDoesNotMute() {
    let frames = path([(0.95, 0.95), (0.95, 0.95)]) + path([(0.95, 0.95), (0.95, 0.95)], start: 0.8)
    #expect(!Trace(frames: frames).replay().contains(.doubleTapped(.topRight)))
}

@Test func longPressInTheCornerIsNotATap() {
    let hold = (0..<40).map { _ in (0.95, 0.95) }
    let frames = path(hold) + path([(0.95, 0.95)], start: 0.5)
    #expect(!Trace(frames: frames).replay().contains(.doubleTapped(.topRight)))
}

@Test func topLeftCornerListensOnlyWhenEnabled() {
    let frames = path([(0.05, 0.95), (0.05, 0.95)]) + path([(0.05, 0.95), (0.05, 0.95)], start: 0.2)
    #expect(!Trace(frames: frames).replay().contains(.doubleTapped(.topLeft)))
    let both = config { $0.corners = [.topLeft, .topRight] }
    #expect(Trace(frames: frames).replay(config: both).last == .doubleTapped(.topLeft))
}

@Test func tapsInDifferentCornersDoNotPair() {
    let both = config { $0.corners = [.topLeft, .topRight] }
    let frames = path([(0.05, 0.95), (0.05, 0.95)]) + path([(0.95, 0.95), (0.95, 0.95)], start: 0.2)
    let events = Trace(frames: frames).replay(config: both)
    #expect(!events.contains(.doubleTapped(.topLeft)) && !events.contains(.doubleTapped(.topRight)))
}

@Test func slideFromTheTopLeftCornerStillSlides() {
    let both = config { $0.corners = [.topLeft] }
    let events = Trace(frames: path([(0.03, 0.95), (0.03, 0.9), (0.03, 0.8)])).replay(config: both)
    #expect(events.contains(.began(.left)))
}
