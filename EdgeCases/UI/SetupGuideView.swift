import SwiftUI

/// First-run guide: grant Accessibility, then make a first slide.
struct SetupGuideView: View {
    let edges: EdgeController
    let onDone: () -> Void
    /// Slides before the guide opened don't count.
    @State private var slidesAtStart: Int?

    var body: some View {
        let slid = slidesAtStart.map { edges.slidesSeen > $0 } ?? false
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Welcome to EdgeCases").font(.title2.weight(.semibold))
                Text("Slide along the edges of your trackpad to change brightness and volume.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TrackpadIllustration(swapSides: edges.preferences.swapSides, highlightRight: edges.isTrusted && !slid)

            VStack(spacing: 14) {
                GuideStep(number: 1, done: edges.isTrusted, title: "Allow Accessibility access",
                          detail: "EdgeCases presses the brightness and volume keys for you, which macOS only allows with this access.") {
                    if !edges.isTrusted {
                        Button("Open Accessibility Settings") { Accessibility.openSettings() }
                    }
                }
                GuideStep(number: 2, done: slid, title: "Try your first slide",
                          detail: "Put one finger on the right edge of the trackpad and slide it up or down.") {
                    EmptyView()
                }
            }

            HStack {
                Text("Settings live in the menu bar icon.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(slid ? "Done" : "Skip", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear { slidesAtStart = edges.slidesSeen }
    }
}

private struct GuideStep<Action: View>: View {
    let number: Int
    let done: Bool
    let title: String
    let detail: String
    @ViewBuilder var action: Action

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(done ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.quaternary))
                if done {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                } else {
                    Text("\(number)").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 24, height: 24)
            .animation(.spring(duration: 0.3), value: done)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                action
            }
            Spacer(minLength: 0)
        }
    }
}

/// A trackpad with its two side edges marked, and an arrow on the one to try.
struct TrackpadIllustration: View {
    let swapSides: Bool
    var highlightRight = false

    var body: some View {
        let (left, right) = swapSides
            ? (("Volume", Color.blue), ("Brightness", Color.orange))
            : (("Brightness", Color.orange), ("Volume", Color.blue))
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.quaternary.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.quaternary))
            HStack {
                EdgeStrip(label: left.0, tint: left.1, active: false)
                Spacer()
                EdgeStrip(label: right.0, tint: right.1, active: highlightRight)
            }
            .padding(6)
        }
        .frame(width: 220, height: 140)
    }
}

private struct EdgeStrip: View {
    let label: String
    let tint: Color
    let active: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(tint.opacity(active ? 0.35 : 0.18))
            .frame(width: 26)
            // Overlays don't change the strip's size, so the rotated label can't widen it.
            .overlay {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
            }
            .overlay(alignment: .top) {
                if active {
                    Image(systemName: "arrow.up.and.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .padding(.top, 8)
                }
            }
    }
}
