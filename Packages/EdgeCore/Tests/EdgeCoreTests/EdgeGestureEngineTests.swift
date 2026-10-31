import Testing
@testable import EdgeCore

/// Feeds one finger through a path of (x, y) points and collects every event.
private func slide(_ path: [(Double, Double)], engine: inout EdgeGestureEngine, id: Int = 1) -> [EdgeEvent] {
    var events: [EdgeEvent] = []
    for (x, y) in path {
        events += engine.process([Contact(id: id, x: x, y: y)])
    }
    return events + engine.process([])
}

@Test func slideUpTheRightEdgeSteps() {
    var engine = EdgeGestureEngine()
    let events = slide([(0.97, 0.2), (0.97, 0.23), (0.97, 0.28), (0.96, 0.33)], engine: &engine)
    #expect(events == [.touched(.right), .began(.right), .step(.right, 1), .step(.right, 1), .ended(.right)])
}

@Test func slideDownTheLeftEdgeStepsNegative() {
    var engine = EdgeGestureEngine()
    let events = slide([(0.02, 0.8), (0.02, 0.77), (0.02, 0.6)], engine: &engine)
    #expect(events == [.touched(.left), .began(.left), .step(.left, -3), .ended(.left)])
}

@Test func touchInTheMiddleIsIgnored() {
    var engine = EdgeGestureEngine()
    #expect(slide([(0.5, 0.2), (0.5, 0.6)], engine: &engine).isEmpty)
}

@Test func movingSidewaysFromTheEdgeIsPointing() {
    var engine = EdgeGestureEngine()
    let events = slide([(0.98, 0.5), (0.9, 0.51), (0.9, 0.8)], engine: &engine)
    #expect(events == [.touched(.right), .cancelled(.right)])
}

@Test func secondFingerEndsTheSlide() {
    var engine = EdgeGestureEngine()
    _ = engine.process([Contact(id: 1, x: 0.98, y: 0.2)])
    _ = engine.process([Contact(id: 1, x: 0.98, y: 0.3)])
    let events = engine.process([Contact(id: 1, x: 0.98, y: 0.3), Contact(id: 2, x: 0.5, y: 0.5)])
    #expect(events == [.ended(.right)])
    // Lifting only the first finger doesn't restart anything until every finger is up.
    #expect(engine.process([Contact(id: 2, x: 0.98, y: 0.5)]).isEmpty)
    #expect(engine.process([]).isEmpty)
    #expect(engine.process([Contact(id: 3, x: 0.98, y: 0.5)]) == [.touched(.right)])
}

@Test func twoFingersOnTheEdgeAreIgnored() {
    var engine = EdgeGestureEngine()
    #expect(engine.process([Contact(id: 1, x: 0.98, y: 0.3), Contact(id: 2, x: 0.98, y: 0.5)]).isEmpty)
    #expect(engine.process([Contact(id: 1, x: 0.98, y: 0.6), Contact(id: 2, x: 0.98, y: 0.8)]).isEmpty)
}

@Test func resetEndsASlide() {
    var engine = EdgeGestureEngine()
    _ = engine.process([Contact(id: 1, x: 0.02, y: 0.2)])
    _ = engine.process([Contact(id: 1, x: 0.02, y: 0.3)])
    #expect(engine.isSliding)
    #expect(engine.reset() == [.ended(.left)])
    #expect(!engine.isSliding)
}
