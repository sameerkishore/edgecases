import AppKit
import SwiftUI

/// `EdgeCases -snapshot <folder>` renders the panel, Settings, and setup guide in light and dark
/// to PNGs, then quits. For checking the design without clicking through the app.
@MainActor
enum Snapshot {
    static func render(edges: EdgeController, to folder: URL) {
        edges.levels.refresh()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let views: [(String, AnyView)] = [
            ("panel", AnyView(PanelRoot(edges: edges))),
            ("settings", AnyView(PanelRoot(edges: edges, page: .settings))),
            ("guide", AnyView(SetupGuideView(edges: edges) {})),
        ]
        for (name, view) in views {
            for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                let host = NSHostingView(rootView: view.background(Color(nsColor: .windowBackgroundColor)))
                host.appearance = NSAppearance(named: appearance)
                host.setFrameSize(host.fittingSize)
                let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
                window.appearance = host.appearance
                window.contentView = host
                host.layoutSubtreeIfNeeded()
                host.displayIfNeeded()
                guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { continue }
                host.cacheDisplay(in: host.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?
                    .write(to: folder.appending(path: "\(name)-\(suffix).png"))
            }
        }
    }
}
