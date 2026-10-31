import SwiftUI

@main
struct EdgeCasesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            PanelRoot(edges: delegate.edges, onShowGuide: delegate.showSetupGuide)
        } label: {
            Image(systemName: "rectangle.and.hand.point.up.left")
        }
        .menuBarExtraStyle(.window)
    }
}
