import AppKit
import EdgeCore

/// What a corner double-tap does.
enum CornerAction: Codable, Equatable {
    case none
    case mute
    case playPause
    case shortcut(KeyCombo)
    case openApp(path: String)

    /// For the menu and the row's detail line.
    var summary: String {
        switch self {
        case .none: "Off"
        case .mute: "Mute"
        case .playPause: "Play or Pause"
        case .shortcut(let combo): combo.display
        case .openApp(let path): Self.appName(path)
        }
    }

    var detail: String {
        switch self {
        case .none: "Double-tap does nothing"
        case .mute: "Double-tap to mute"
        case .playPause: "Double-tap to play or pause"
        case .shortcut(let combo): "Double-tap presses \(combo.display)"
        case .openApp(let path): "Double-tap opens \(Self.appName(path))"
        }
    }

    @MainActor
    func perform() {
        switch self {
        case .none: break
        case .mute: MediaKey.mute.press()
        case .playPause: MediaKey.play.press()
        case .shortcut(let combo): combo.post()
        case .openApp(let path):
            NSWorkspace.shared.openApplication(at: URL(filePath: path), configuration: NSWorkspace.OpenConfiguration())
        }
    }

    static func appName(_ path: String) -> String {
        FileManager.default.displayName(atPath: path).replacing(/\.app$/, with: "")
    }
}

extension Corner {
    var title: String {
        switch self {
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        }
    }

    var symbol: String {
        switch self {
        case .topLeft: "arrow.up.left"
        case .topRight: "arrow.up.right"
        }
    }
}
