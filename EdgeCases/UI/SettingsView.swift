import SwiftUI

/// Set-once options, shown in the panel in place of the main page.
struct SettingsView: View {
    let edges: EdgeController
    var onShowGuide: () -> Void = {}
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
                SectionTitle("While Sliding")
                SettingRow(icon: "cursorarrow", title: "Freeze Cursor", detail: "Pointer stays put", isOn: $prefs.freezeCursor)
                SettingRow(icon: "dial.low.fill", title: "Fine Control", detail: "Hold ⇧⌥ for quarter steps", isOn: $prefs.fineControl)
            }

            Divider()

            VStack(spacing: 10) {
                SectionTitle("General")
                SettingRow(icon: "circle.lefthalf.filled", title: "Appearance") {
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
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}
