import SwiftUI

/// Brightness and volume, each drawn against the side of the card that matches the trackpad edge
/// that controls it.
struct LevelsCard: View {
    let levels: SystemLevels
    let swapSides: Bool

    var body: some View {
        let brightness = Level(title: "Brightness", symbol: "sun.max.fill", tint: .orange, value: levels.brightness)
        let volume = Level(
            title: "Volume",
            symbol: levels.muted ? "speaker.slash.fill" : "speaker.wave.2.fill",
            tint: .blue,
            value: levels.volume,
            note: levels.muted ? "Muted" : nil
        )
        let (left, right) = swapSides ? (volume, brightness) : (brightness, volume)
        HStack(spacing: 10) {
            LevelBar(level: left)
            LevelReadout(level: left, alignment: .leading)
            Spacer()
            LevelReadout(level: right, alignment: .trailing)
            LevelBar(level: right)
        }
        .padding(10)
        .frame(height: 92)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeOut(duration: 0.15), value: levels.brightness)
        .animation(.easeOut(duration: 0.15), value: levels.volume)
    }
}

private struct Level {
    let title: String
    let symbol: String
    let tint: Color
    let value: Double?
    var note: String?
}

private struct LevelBar: View {
    let level: Level

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(level.tint.gradient)
                    .frame(height: geometry.size.height * (level.value ?? 0))
                    .opacity(level.note == nil ? 1 : 0.35)
            }
        }
        .frame(width: 5)
    }
}

private struct LevelReadout: View {
    let level: Level
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Label(level.title.uppercased(), systemImage: level.symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(TintedIconLabelStyle(tint: level.tint))
            Group {
                if let note = level.note {
                    Text(note).font(.system(size: 26, weight: .light, design: .rounded))
                } else if let value = level.value {
                    (Text((value * 100).rounded().formatted())
                        + Text("%").font(.system(size: 16, weight: .light, design: .rounded)))
                        .font(.system(size: 34, weight: .light, design: .rounded))
                } else {
                    Text("—").font(.system(size: 34, weight: .light, design: .rounded)).foregroundStyle(.tertiary)
                }
            }
            .monospacedDigit()
            .contentTransition(.numericText())
        }
    }
}

private struct TintedIconLabelStyle: LabelStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(tint)
            configuration.title
        }
    }
}
