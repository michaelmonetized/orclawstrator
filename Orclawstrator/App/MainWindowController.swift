import Cocoa

class MainWindowController: NSWindowController {
    
    private var dashboardViewController: DashboardViewController!
    
    convenience init() {
        // Create window programmatically
        let window = MainWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        
        // Setup window properties
        window.title = "Orclawstrator"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("OrclawstratorMainWindow")
        window.minSize = NSSize(width: 1000, height: 600)
        
        // Create split view controller for sidebar + dashboard
        let splitViewController = NSSplitViewController()
        
        // Left sidebar
        let sidebarViewController = SidebarViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 220
        sidebarItem.maximumThickness = 320
        sidebarItem.canCollapse = true
        splitViewController.addSplitViewItem(sidebarItem)
        
        // Main dashboard
        dashboardViewController = DashboardViewController()
        let dashboardItem = NSSplitViewItem(viewController: dashboardViewController)
        dashboardItem.minimumThickness = 700
        splitViewController.addSplitViewItem(dashboardItem)
        
        // Apply dark appearance
        splitViewController.view.appearance = NSAppearance(named: .darkAqua)
        
        window.contentViewController = splitViewController
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Custom Main Window with Gradient Background

class MainWindow: NSWindow {
    
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // Apply dark appearance
        self.appearance = NSAppearance(named: .darkAqua)
    }
}
