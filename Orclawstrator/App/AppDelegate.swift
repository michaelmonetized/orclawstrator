import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create main window controller
        windowController = MainWindowController()
        windowController.showWindow(nil)
        
        // Activate app
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        true
    }
}
