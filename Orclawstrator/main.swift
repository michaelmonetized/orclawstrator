import Cocoa

let app = NSApplication.shared

// This makes the app appear in the dock and be cmd+tab-able
app.setActivationPolicy(.regular)

let delegate = AppDelegate()
app.delegate = delegate

// Activate and bring to front
app.activate(ignoringOtherApps: true)

app.run()
