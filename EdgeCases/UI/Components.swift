import SwiftUI

/// A settings row: round icon, title and detail, and a control on the right.
struct SettingRow<Control: View>: View {
    let icon: String
    var tint: Color = .brand
    let title: String
    var detail: String?
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: 10) {
            RowIcon(symbol: icon, tint: tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).lineLimit(1)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            control
        }
    }
}

extension SettingRow where Control == AnyView {
    /// A row with a switch.
    init(icon: String, tint: Color = .brand, title: String, detail: String? = nil, isOn: Binding<Bool>) {
        self.init(icon: icon, tint: tint, title: title, detail: detail) {
            AnyView(Toggle("", isOn: isOn).toggleStyle(.switch).controlSize(.small).labelsHidden())
        }
    }
}

struct RowIcon: View {
    let symbol: String
    var tint: Color = .brand

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Circle().fill(tint.gradient))
    }
}

/// A labelled slider with its value on the right and tick marks at each step.
struct SliderRow: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                RowIcon(symbol: icon, tint: .secondary)
                Text(title)
                Spacer()
                Text(format(value)).monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
                .padding(.leading, 36)
        }
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The panel's top bar: app name and whether it's working.
struct PanelHeader: View {
    let title: String
    let edges: EdgeController

    var body: some View {
        HStack(spacing: 8) {
            Image("MenuBarIcon")
                .renderingMode(.template)
                .foregroundStyle(Color.brand)
            Text(title).font(.headline)
            Spacer()
            StatusBadge(edges: edges)
        }
    }
}

struct StatusBadge: View {
    let edges: EdgeController

    var body: some View {
        let (label, color): (String, Color) =
            if !edges.trackpadFound { ("No trackpad", .orange) }
            else if !edges.isTrusted { ("Needs access", .orange) }
            else if !edges.preferences.enabled { ("Paused", .secondary) }
            else { ("Ready", .green) }
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

extension Color {
    /// EdgeCases coral. Unlike `.accentColor`, it stays coral when a system accent colour is set.
    static let brand = Color("AccentColor")
}

extension Double {
    var percent: String { formatted(.percent.precision(.fractionLength(0))) }
}
