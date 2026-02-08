import Cocoa

class MainWindowController: NSWindowController {
    
    private var splitViewController: NSSplitViewController!
    private var sidebarViewController: SidebarViewController!
    private var dashboardViewController: DashboardViewController!
    private var detailViewController: ProjectDetailViewController?
    
    // Track current main content
    private var mainContentItem: NSSplitViewItem?
    
    convenience init() {
        // Create window
        let window = MainWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        
        // Setup window properties
        window.title = "🦞 Orclawstrator"
        window.backgroundColor = Catppuccin.crust
        window.center()
        window.minSize = NSSize(width: 900, height: 600)
        
        // Create split view with sidebar + dashboard
        setupSplitView()
    }
    
    private func setupSplitView() {
        // Create the view controllers
        sidebarViewController = SidebarViewController()
        dashboardViewController = DashboardViewController()
        
        // Set up project selection callback
        dashboardViewController.onProjectSelected = { [weak self] project in
            self?.showProjectDetail(project)
        }
        
        // Create split view controller
        splitViewController = NSSplitViewController()
        
        // Sidebar item
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 220
        sidebarItem.maximumThickness = 320
        sidebarItem.canCollapse = true
        sidebarItem.holdingPriority = .defaultLow
        
        // Dashboard item (main content)
        let dashboardItem = NSSplitViewItem(viewController: dashboardViewController)
        dashboardItem.minimumThickness = 600
        mainContentItem = dashboardItem
        
        // Add items to split view
        splitViewController.addSplitViewItem(sidebarItem)
        splitViewController.addSplitViewItem(dashboardItem)
        
        // Configure split view appearance
        splitViewController.splitView.dividerStyle = .thin
        splitViewController.splitView.isVertical = true
        
        // Set as window content
        window?.contentViewController = splitViewController
    }
    
    // MARK: - Navigation
    
    func showProjectDetail(_ project: Project) {
        // Create detail view controller
        let detailVC = ProjectDetailViewController()
        detailVC.configure(with: project)
        detailVC.onBack = { [weak self] in
            self?.showDashboard()
        }
        
        // Replace main content
        if let mainItem = mainContentItem {
            splitViewController.removeSplitViewItem(mainItem)
        }
        
        let detailItem = NSSplitViewItem(viewController: detailVC)
        detailItem.minimumThickness = 600
        mainContentItem = detailItem
        
        splitViewController.addSplitViewItem(detailItem)
        detailViewController = detailVC
        
        // Update window title
        window?.title = "🦞 \(project.name)"
    }
    
    func showDashboard() {
        // Remove detail view if present
        if let mainItem = mainContentItem {
            splitViewController.removeSplitViewItem(mainItem)
        }
        
        // Add dashboard back
        let dashboardItem = NSSplitViewItem(viewController: dashboardViewController)
        dashboardItem.minimumThickness = 600
        mainContentItem = dashboardItem
        
        splitViewController.addSplitViewItem(dashboardItem)
        detailViewController = nil
        
        // Restore window title
        window?.title = "🦞 Orclawstrator"
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Custom Main Window with Dark Theme

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
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .visible
    }
}
