import ApplicationServices

/// Posting media keys needs the app in System Settings → Privacy & Security → Accessibility.
enum Accessibility {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that links to the Accessibility settings, if access isn't granted yet.
    @discardableResult
    static func requestIfNeeded() -> Bool {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}
