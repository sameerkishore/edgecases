import os

/// `/usr/bin/log stream --level info --predicate 'subsystem == "app.edgecases.EdgeCases"'`
enum Log {
    static let touch = Logger(subsystem: "app.edgecases.EdgeCases", category: "touch")
    static let action = Logger(subsystem: "app.edgecases.EdgeCases", category: "action")
}
