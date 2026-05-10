import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSWindow.allowsAutomaticWindowTabbing = false

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let keyWindow = NSApp.keyWindow {
                keyWindow.setContentSize(NSSize(width: 1016, height: 860))
                keyWindow.makeKeyAndOrderFront(nil)
            } else if let mainWindow = NSApp.mainWindow {
                mainWindow.setContentSize(NSSize(width: 1016, height: 860))
                mainWindow.makeKeyAndOrderFront(nil)
            } else if let first = NSApp.windows.first {
                first.setContentSize(NSSize(width: 1016, height: 860))
                first.makeKeyAndOrderFront(nil)
            }
        }
    }

    func application(_ app: NSApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        false
    }

    func application(_ app: NSApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        false
    }
}
