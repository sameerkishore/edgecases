import AppKit

/// Trackpad ticks. The public NSHapticFeedbackManager is faint, so this plays the actuator's own
/// waveforms directly (as HapticKey does), falling back to the public API if that fails.
enum HapticStrength: String, CaseIterable {
    case off, light, medium, strong

    var title: String { rawValue.capitalized }

    /// Waveform IDs on the built-in trackpad's actuator. Other IDs exist; the Debug menu plays them.
    var actuationID: Int32? {
        switch self {
        case .off: nil
        case .light: 3
        case .medium: 4
        case .strong: 6
        }
    }
}

@MainActor
enum Haptics {
    static func tick(_ strength: HapticStrength) {
        guard let id = strength.actuationID else { return }
        play(id)
    }

    static func play(_ actuationID: Int32) {
        if !ECHapticActuate(actuationID) {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
    }
}
