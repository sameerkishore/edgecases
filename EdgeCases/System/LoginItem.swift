import ServiceManagement
import os

/// Open at Login. Registers the app where it is now, so install it in /Applications first
/// (`scripts/install.sh`) rather than turning this on for a copy in build/.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Log.action.error("Open at Login couldn't be changed: \(error)")
        }
    }
}
