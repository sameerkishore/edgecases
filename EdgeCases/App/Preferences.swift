import EdgeCore
import Foundation

/// The user's choices, kept in UserDefaults. `onChange` runs after every change.
@MainActor
final class Preferences {
    private let defaults = UserDefaults.standard
    var onChange: () -> Void = {}

    var enabled: Bool {
        get { bool("enabled", default: true) }
        set { set(newValue, "enabled") }
    }

    var hapticStrength: HapticStrength {
        get { defaults.string(forKey: "hapticStrength").flatMap(HapticStrength.init) ?? .medium }
        set { set(newValue.rawValue, "hapticStrength") }
    }

    /// Brightness on the right, volume on the left.
    var swapSides: Bool {
        get { bool("swapSides", default: false) }
        set { set(newValue, "swapSides") }
    }

    var freezeCursor: Bool {
        get { bool("freezeCursor", default: true) }
        set { set(newValue, "freezeCursor") }
    }

    /// Shift-Option while sliding gives quarter steps.
    var fineControl: Bool {
        get { bool("fineControl", default: true) }
        set { set(newValue, "fineControl") }
    }

    var edgeWidth: Double {
        get { double("edgeWidth", default: EdgeConfig().edgeWidth) }
        set { set(newValue, "edgeWidth") }
    }

    var sensitivity: Double {
        get { double("sensitivity", default: 1) }
        set { set(newValue, "sensitivity") }
    }

    var bottomQuarterOnly: Bool {
        get { bool("bottomQuarterOnly", default: false) }
        set { set(newValue, "bottomQuarterOnly") }
    }

    var requireModifier: Bool {
        get { bool("requireModifier", default: false) }
        set { set(newValue, "requireModifier") }
    }

    var mediaStrip: Bool {
        get { bool("mediaStrip", default: true) }
        set { set(newValue, "mediaStrip") }
    }

    var tapToPlay: Bool {
        get { bool("tapToPlay", default: false) }
        set { set(newValue, "tapToPlay") }
    }

    var quickMute: Bool {
        get { bool("quickMute", default: true) }
        set { set(newValue, "quickMute") }
    }

    var config: EdgeConfig {
        var config = EdgeConfig()
        config.edgeWidth = edgeWidth
        config.sensitivity = sensitivity
        config.bottomQuarterOnly = bottomQuarterOnly
        config.requireModifier = requireModifier
        config.mediaStrip = mediaStrip
        config.tapToPlay = tapToPlay
        config.quickMute = quickMute
        return config
    }

    private func bool(_ key: String, default value: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? value : defaults.bool(forKey: key)
    }

    private func double(_ key: String, default value: Double) -> Double {
        defaults.object(forKey: key) == nil ? value : defaults.double(forKey: key)
    }

    private func set(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        onChange()
    }
}
