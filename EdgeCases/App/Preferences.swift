import AppKit
import EdgeCore
import Observation

enum Appearance: String, CaseIterable {
    case system, light, dark

    var title: String { rawValue.capitalized }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

/// The user's choices, kept in UserDefaults. `onChange` runs after every change.
@Observable
@MainActor
final class Preferences {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored var onChange: () -> Void = {}

    var enabled: Bool { didSet { save(enabled, "enabled") } }
    var hapticStrength: HapticStrength { didSet { save(hapticStrength.rawValue, "hapticStrength") } }
    /// Brightness on the right, volume on the left.
    var swapSides: Bool { didSet { save(swapSides, "swapSides") } }
    var freezeCursor: Bool { didSet { save(freezeCursor, "freezeCursor") } }
    /// Shift-Option while sliding gives quarter steps.
    var fineControl: Bool { didSet { save(fineControl, "fineControl") } }
    var edgeWidth: Double { didSet { save(edgeWidth, "edgeWidth") } }
    var sensitivity: Double { didSet { save(sensitivity, "sensitivity") } }
    var bottomQuarterOnly: Bool { didSet { save(bottomQuarterOnly, "bottomQuarterOnly") } }
    var requireModifier: Bool { didSet { save(requireModifier, "requireModifier") } }
    var mediaStrip: Bool { didSet { save(mediaStrip, "mediaStrip") } }
    var tapToPlay: Bool { didSet { save(tapToPlay, "tapToPlay") } }
    var topLeftAction: CornerAction { didSet { save(Self.encode(topLeftAction), "topLeftAction") } }
    var topRightAction: CornerAction { didSet { save(Self.encode(topRightAction), "topRightAction") } }
    var appearance: Appearance { didSet { save(appearance.rawValue, "appearance") } }
    var hasSeenSetupGuide: Bool { didSet { save(hasSeenSetupGuide, "hasSeenSetupGuide") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func value<T>(_ key: String, _ fallback: T) -> T { defaults.object(forKey: key) as? T ?? fallback }
        enabled = value("enabled", true)
        hapticStrength = HapticStrength(rawValue: value("hapticStrength", "")) ?? .medium
        swapSides = value("swapSides", false)
        freezeCursor = value("freezeCursor", true)
        fineControl = value("fineControl", true)
        edgeWidth = value("edgeWidth", EdgeConfig().edgeWidth)
        sensitivity = value("sensitivity", 1.0)
        bottomQuarterOnly = value("bottomQuarterOnly", false)
        requireModifier = value("requireModifier", false)
        mediaStrip = value("mediaStrip", true)
        tapToPlay = value("tapToPlay", false)
        topLeftAction = Self.decode(defaults.data(forKey: "topLeftAction")) ?? .none
        // Before corner actions, the top-right corner was a Quick Mute switch.
        topRightAction = Self.decode(defaults.data(forKey: "topRightAction")) ?? (value("quickMute", true) ? .mute : .none)
        appearance = Appearance(rawValue: value("appearance", "")) ?? .system
        hasSeenSetupGuide = value("hasSeenSetupGuide", false)
    }

    var config: EdgeConfig {
        var config = EdgeConfig()
        config.edgeWidth = edgeWidth
        config.sensitivity = sensitivity
        config.bottomQuarterOnly = bottomQuarterOnly
        config.requireModifier = requireModifier
        config.mediaStrip = mediaStrip
        config.tapToPlay = tapToPlay
        config.corners = Set(Corner.allCases.filter { action(for: $0) != .none })
        return config
    }

    func action(for corner: Corner) -> CornerAction {
        switch corner {
        case .topLeft: topLeftAction
        case .topRight: topRightAction
        }
    }

    func setAction(_ action: CornerAction, for corner: Corner) {
        switch corner {
        case .topLeft: topLeftAction = action
        case .topRight: topRightAction = action
        }
    }

    private static func encode(_ action: CornerAction) -> Data {
        (try? JSONEncoder().encode(action)) ?? Data()
    }

    private static func decode(_ data: Data?) -> CornerAction? {
        data.flatMap { try? JSONDecoder().decode(CornerAction.self, from: $0) }
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        onChange()
    }
}
