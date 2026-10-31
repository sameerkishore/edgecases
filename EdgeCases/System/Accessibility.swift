import AppKit
import ApplicationServices

/// Posting media keys needs the app in System Settings → Privacy & Security → Accessibility.
enum Accessibility {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that links to the Accessibility settings, if access isn't granted yet.
    @discardableResult
    static func requestIfNeeded() -> Bool {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    /// Adds the app to the Accessibility list (switched off) and opens it there.
    static func openSettings() {
        requestIfNeeded()
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
