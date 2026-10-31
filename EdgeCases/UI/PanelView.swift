import SwiftUI

/// What the menu bar icon opens: the main page, or Settings in its place.
struct PanelRoot: View {
    let edges: EdgeController
    var onShowGuide: () -> Void = {}
    @State var page = Page.main

    enum Page { case main, settings }

    var body: some View {
        Group {
            switch page {
            case .main: PanelView(edges: edges) { page = .settings }
            case .settings: SettingsView(edges: edges, onShowGuide: onShowGuide) { page = .main }
            }
        }
        .frame(width: 300)
        .tint(.brand)
    }
}

/// Levels, everyday toggles, and slide feel.
struct PanelView: View {
    let edges: EdgeController
    let onSettings: () -> Void
    @State private var refresh: Timer?

    var body: some View {
        @Bindable var prefs = edges.preferences
        VStack(spacing: 12) {
            PanelHeader(title: "EdgeCases", edges: edges)
            if edges.trackpadFound && !edges.isTrusted {
                AccessNotice()
            }
            LevelsCard(levels: edges.levels, swapSides: prefs.swapSides)

            VStack(spacing: 10) {
                SettingRow(icon: "hand.tap.fill", tint: prefs.hapticStrength == .off ? .secondary : .brand,
                           title: "Haptic Feedback", detail: "Ticks as you slide") {
                    Picker("", selection: $prefs.hapticStrength) {
                        ForEach(HapticStrength.allCases, id: \.self) { Text($0.title) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .controlSize(.small)
                }
                SettingRow(icon: "forward.fill", title: "Media Strip", detail: "Slide the bottom edge to skip", isOn: $prefs.mediaStrip)
                SettingRow(icon: "playpause.fill", title: "Tap to Play or Pause", detail: "Tap the bottom edge", isOn: $prefs.tapToPlay)
            }

            Divider()

            VStack(spacing: 12) {
                SliderRow(icon: "gauge.with.dots.needle.50percent", title: "Sensitivity", value: $prefs.sensitivity,
                          range: 0.5...2, step: 0.25) { $0.formatted() + "×" }
                SliderRow(icon: "arrow.left.and.right", title: "Edge Width", value: $prefs.edgeWidth,
                          range: 0.03...0.12, step: 0.01) { $0.percent }
            }

            Divider()

            HStack {
                Button(action: onSettings) {
                    Label("Settings", systemImage: "gearshape")
                }
                Spacer()
                Toggle(isOn: $prefs.enabled) {
                    Text("On").font(.caption).foregroundStyle(.secondary)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .help("Pause or resume edge gestures")
                Button { NSApp.terminate(nil) } label: {
                    Image(systemName: "power")
                }
                .foregroundStyle(.secondary)
                .help("Quit EdgeCases")
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .onChange(of: prefs.hapticStrength) { _, strength in Haptics.tick(strength) }
        .onAppear {
            edges.levels.refresh()
            refresh = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                MainActor.assumeIsolated { edges.levels.refresh() }
            }
        }
        .onDisappear {
            refresh?.invalidate()
            refresh = nil
        }
    }
}

private struct AccessNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("EdgeCases needs Accessibility access to change brightness and volume.")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Accessibility Settings") { Accessibility.openSettings() }
                    .controlSize(.small)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
