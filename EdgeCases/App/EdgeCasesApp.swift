import SwiftUI

@main
struct EdgeCasesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            PanelRoot(edges: delegate.edges, onShowGuide: delegate.showSetupGuide, onCheckForUpdates: delegate.checkForUpdates)
        } label: {
            // An empty trackpad while paused.
            Image(delegate.edges.preferences.enabled ? "MenuBarIcon" : "MenuBarIconPaused")
        }
        .menuBarExtraStyle(.window)
    }
}
