import AppKit
import Carbon.HIToolbox

/// A keyboard shortcut recorded from a real key press, to replay on a corner double-tap.
struct KeyCombo: Codable, Equatable {
    var keyCode: UInt16
    /// Command, Control, Option, Shift and Fn, as CGEventFlags bits.
    var flags: UInt64
    /// What the key is called, worked out when it was recorded.
    var key: String

    private static let kept: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn]

    init?(event: CGEvent) {
        guard event.type == .keyDown else { return nil }
        keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        flags = event.flags.intersection(Self.kept).rawValue
        key = Self.name(of: keyCode)
            ?? NSEvent(cgEvent: event)?.characters(byApplyingModifiers: [])?.uppercased()
            ?? "Key \(keyCode)"
    }

    /// Escape on its own cancels recording rather than becoming the shortcut.
    var isPlainEscape: Bool {
        Int(keyCode) == kVK_Escape && CGEventFlags(rawValue: flags).intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty
    }

    /// In the order macOS menus show them, like ⌃⌘Q.
    var display: String {
        let f = CGEventFlags(rawValue: flags)
        var text = ""
        if f.contains(.maskControl) { text += "⌃" }
        if f.contains(.maskAlternate) { text += "⌥" }
        if f.contains(.maskShift) { text += "⇧" }
        if f.contains(.maskCommand) { text += "⌘" }
        return text + key
    }

    func post() {
        let source = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { continue }
            event.flags = CGEventFlags(rawValue: flags)
            event.post(tap: .cghidEventTap)
        }
    }

    /// Keys that don't type a character.
    private static func name(of code: UInt16) -> String? {
        let names: [Int: String] = [
            kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
            kVK_Escape: "⎋", kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
            kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
            kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
            kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18",
            kVK_F19: "F19", kVK_F20: "F20",
        ]
        return names[Int(code)]
    }
}
