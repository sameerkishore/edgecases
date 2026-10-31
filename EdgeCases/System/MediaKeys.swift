import AppKit

/// Posts the same events as the keyboard's media keys, so macOS shows its own on-screen display and
/// uses its own step sizes. Posting needs Accessibility access.
enum MediaKey: Int {
    // NX_KEYTYPE_* from IOKit/hidsystem/ev_keymap.h
    case soundUp = 0
    case soundDown = 1
    case brightnessUp = 2
    case brightnessDown = 3
    case mute = 7
    case play = 16
    case next = 17
    case previous = 18

    @MainActor
    func press(modifiers: NSEvent.ModifierFlags = []) {
        for down in [true, false] {
            let state = down ? 0xA : 0xB
            let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state << 8)).union(modifiers),
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8, // NX_SUBTYPE_AUX_CONTROL_BUTTONS
                data1: (rawValue << 16) | (state << 8),
                data2: -1
            )
            event?.cgEvent?.post(tap: .cghidEventTap)
        }
    }
}
