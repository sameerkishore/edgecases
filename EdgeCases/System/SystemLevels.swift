import AudioToolbox
import CoreAudio
import CoreGraphics
import Foundation
import Observation

/// The current built-in display brightness and output volume, for the panel. Read on demand;
/// the panel refreshes it while open and after each step.
@Observable
@MainActor
final class SystemLevels {
    /// 0…1, or nil when there's no built-in display (lid closed) or the read failed.
    private(set) var brightness: Double?
    /// 0…1, or nil when the output device has no volume control (HDMI, some interfaces).
    private(set) var volume: Double?
    private(set) var muted = false

    func refresh() {
        let brightness = Self.readBrightness()
        let (volume, muted) = Self.readVolume()
        if brightness != self.brightness { self.brightness = brightness }
        if volume != self.volume { self.volume = volume }
        if muted != self.muted { self.muted = muted }
    }

    /// Key events land a moment after they're posted.
    func refreshSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.refresh()
        }
    }

    // MARK: Brightness (DisplayServices, private)

    private typealias GetBrightness = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

    private static let getBrightness: GetBrightness? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW),
              let symbol = dlsym(handle, "DisplayServicesGetBrightness") else { return nil }
        return unsafeBitCast(symbol, to: GetBrightness.self)
    }()

    private static func readBrightness() -> Double? {
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard let getBrightness, CGGetOnlineDisplayList(16, &displays, &count) == .success,
              let builtIn = displays.prefix(Int(count)).first(where: { CGDisplayIsBuiltin($0) != 0 }) else { return nil }
        var value: Float = 0
        return getBrightness(builtIn, &value) == 0 ? Double(value) : nil
    }

    // MARK: Volume (CoreAudio)

    private static func readVolume() -> (Double?, Bool) {
        var device = AudioObjectID(kAudioObjectUnknown)
        guard read(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal, into: &device) else {
            return (nil, false)
        }
        var volume = Float32(0)
        var muted = UInt32(0)
        let hasVolume = read(device, kAudioHardwareServiceDeviceProperty_VirtualMainVolume, into: &volume)
        _ = read(device, kAudioDevicePropertyMute, into: &muted)
        return (hasVolume ? Double(volume) : nil, muted != 0)
    }

    private static func read<T: BitwiseCopyable>(
        _ object: AudioObjectID, _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioDevicePropertyScopeOutput, into value: inout T
    ) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr
    }
}
