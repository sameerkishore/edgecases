import EdgeCore
import SwiftUI

/// Set-once options, shown in the panel in place of the main page.
struct SettingsView: View {
    let edges: EdgeController
    var onShowGuide: () -> Void = {}
    var onCheckForUpdates: () -> Void = {}
    let onBack: () -> Void
    @State private var openAtLogin = LoginItem.isEnabled

    var body: some View {
        @Bindable var prefs = edges.preferences
        VStack(spacing: 12) {
            PanelHeader(title: "Settings", edges: edges)

            VStack(spacing: 10) {
                SectionTitle("Edges")
                SettingRow(icon: "arrow.left.arrow.right", title: "Swap Sides",
                           detail: prefs.swapSides ? "Left: volume · Right: brightness" : "Left: brightness · Right: volume",
                           isOn: $prefs.swapSides)
                SettingRow(icon: "rectangle.bottomhalf.filled", title: "Bottom Quarter Only",
                           detail: "Ignore side touches higher up", isOn: $prefs.bottomQuarterOnly)
                SettingRow(icon: "option", title: "Require Fn or ⌥",
                           detail: "Only slide while holding one", isOn: $prefs.requireModifier)
            }

            Divider()

            VStack(spacing: 10) {
                SectionTitle("Corners")
                ForEach(Corner.allCases, id: \.self) { CornerRow(corner: $0, edges: edges) }
            }

            Divider()

            VStack(spacing: 10) {
                SectionTitle("While Sliding")
                SettingRow(icon: "cursorarrow", title: "Freeze Cursor", detail: "Pointer stays put", isOn: $prefs.freezeCursor)
                SettingRow(icon: "dial.low.fill", title: "Fine Control", detail: "Hold ⇧⌥ for quarter steps", isOn: $prefs.fineControl)
            }

            Divider()

            VStack(spacing: 10) {
                SectionTitle("General")
                SettingRow(icon: "circle.lefthalf.filled", tint: .secondary, title: "Appearance") {
                    Picker("", selection: $prefs.appearance) {
                        ForEach(Appearance.allCases, id: \.self) { Text($0.title) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .controlSize(.small)
                }
                SettingRow(icon: "power", title: "Open at Login", isOn: Binding(
                    get: { openAtLogin },
                    set: { LoginItem.set($0); openAtLogin = LoginItem.isEnabled }
                ))
            }

            Divider()

            VStack(spacing: 10) {
                SectionTitle("Help")
                SettingRow(icon: "sparkles", tint: .secondary, title: "Setup Guide") {
                    Button("Show", action: onShowGuide).controlSize(.small)
                }
                SettingRow(icon: "arrow.down.circle", tint: .secondary, title: "Updates", detail: "Checked daily") {
                    Button("Check Now", action: onCheckForUpdates).controlSize(.small)
                }
                SettingRow(icon: "record.circle", tint: edges.isRecording ? .red : .secondary, title: "Record Touches",
                           detail: "Save a trace for tuning gestures") {
                    Button(edges.isRecording ? "Stop and Save" : "Start") {
                        edges.isRecording ? edges.stopRecording() : edges.startRecording()
                    }
                    .controlSize(.small)
                }
            }

            Divider()

            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                Spacer()
                Text("Version \(Bundle.main.shortVersion)").font(.caption).foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .onAppear { openAtLogin = LoginItem.isEnabled }
        .onDisappear { edges.stopRecordingShortcut() }
    }
}

/// A corner's double-tap action: a menu of built-in actions, a recorded shortcut, or an app.
private struct CornerRow: View {
    let corner: Corner
    let edges: EdgeController

    var body: some View {
        let prefs = edges.preferences
        let action = prefs.action(for: corner)
        let recording = edges.recordingCorner == corner
        SettingRow(icon: corner.symbol, tint: action == .none ? .secondary : .brand, title: corner.title,
                   detail: recording ? "Press a shortcut, or Esc to cancel" : action.detail) {
            if recording {
                Button("Cancel") { edges.stopRecordingShortcut() }.controlSize(.small)
            } else {
                Menu(action.summary) {
                    choice("Off", .none, current: action)
                    choice("Mute", .mute, current: action)
                    choice("Play or Pause", .playPause, current: action)
                    Divider()
                    Button("Keyboard Shortcut…") { edges.recordShortcut(for: corner) }
                    Button("Open App…") { edges.chooseApp(for: corner) }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .controlSize(.small)
            }
        }
    }

    private func choice(_ title: String, _ value: CornerAction, current: CornerAction) -> some View {
        Button {
            edges.preferences.setAction(value, for: corner)
        } label: {
            if value == current { Label(title, systemImage: "checkmark") } else { Text(title) }
        }
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}
