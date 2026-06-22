import Cocoa

class MainWindowController: NSWindowController {
    
    private var mainContentView: MainContentView!
    private var topStatusBar: TopStatusBar!
    private var bottomStatusBar: BottomStatusBar!
    
    // Track current main content
    private var currentDetailProject: Project?
    
    convenience init() {
        // Create completely chromeless, transparent window
        let window = TransparentWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1400, height: 900),
            styleMask: [.borderless, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        
        // Setup window properties
        window.title = "🦞 Orclawstrator"
        window.center()
        window.minSize = NSSize(width: 1000, height: 700)
        window.isMovableByWindowBackground = false
        
        // Create window content
        setupWindowContent()
    }
    
    private func setupWindowContent() {
        guard let window = window else { return }
        
        // Main container with rounded corners and gradient
        let containerVC = NSViewController()
        let container = GradientContainerView()
        container.frame = NSRect(x: 0, y: 0, width: 1400, height: 900)
        containerVC.view = container
        
        // Top status bar (full width, 44pt height)
        topStatusBar = TopStatusBar()
        topStatusBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(topStatusBar)
        
        // Draggable area covers the top bar
        let dragView = WindowDragView()
        dragView.translatesAutoresizingMaskIntoConstraints = false
        topStatusBar.addSubview(dragView, positioned: .below, relativeTo: nil)
        
        // Main content area (sidebar + dashboard)
        mainContentView = MainContentView()
        mainContentView.translatesAutoresizingMaskIntoConstraints = false
        mainContentView.onProjectSelected = { [weak self] project in
            self?.showProjectDetail(project)
        }
        mainContentView.topStatusBar = topStatusBar
        container.addSubview(mainContentView)
        
        // Bottom status bar (full width, 28pt height)
        bottomStatusBar = BottomStatusBar()
        bottomStatusBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomStatusBar)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Top status bar
            topStatusBar.topAnchor.constraint(equalTo: container.topAnchor),
            topStatusBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topStatusBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topStatusBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Drag view fills the top bar
            dragView.topAnchor.constraint(equalTo: topStatusBar.topAnchor),
            dragView.leadingAnchor.constraint(equalTo: topStatusBar.leadingAnchor),
            dragView.trailingAnchor.constraint(equalTo: topStatusBar.trailingAnchor),
            dragView.bottomAnchor.constraint(equalTo: topStatusBar.bottomAnchor),
            
            // Main content
            mainContentView.topAnchor.constraint(equalTo: topStatusBar.bottomAnchor),
            mainContentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainContentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainContentView.bottomAnchor.constraint(equalTo: bottomStatusBar.topAnchor),
            
            // Bottom status bar
            bottomStatusBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomStatusBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomStatusBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomStatusBar.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        window.contentViewController = containerVC
    }
    
    // MARK: - Navigation
    
    func showProjectDetail(_ project: Project) {
        currentDetailProject = project
        mainContentView.showProjectDetail(project)
        window?.title = "🦞 \(project.name)"
    }
    
    func showDashboard() {
        currentDetailProject = nil
        mainContentView.showDashboard()
        window?.title = "🦞 Orclawstrator"
    }

    func showInbox() {
        currentDetailProject = nil
        mainContentView.showInbox()
        window?.title = "🦞 Inbox"
    }

    func refreshDashboard() {
        mainContentView.showDashboard()
    }

    func getProjects() -> [Project] {
        return ProjectScanner.shared.cachedProjects
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Transparent Window (Chromeless, Semi-transparent)

class TransparentWindow: NSWindow {
    
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // Apply dark appearance
        self.appearance = NSAppearance(named: .darkAqua)
        
        // Make window transparent and borderless
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        
        // Window behavior
        self.level = .normal
        self.collectionBehavior = [.fullScreenPrimary, .managed]
        
        // Hide standard window buttons (traffic lights)
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Gradient Container View (Rounded corners + diagonal gradient)

class GradientContainerView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Diagonal gradient from top-left (base) to bottom-right (crust)
        // with semi-transparency to show wallpaper
        let gradient = NSGradient(colors: [
            Catppuccin.base.withAlphaComponent(0.92),
            Catppuccin.mantle.withAlphaComponent(0.90),
            Catppuccin.crust.withAlphaComponent(0.95)
        ], atLocations: [0.0, 0.5, 1.0], colorSpace: .deviceRGB)
        
        // Draw diagonal gradient (135 degrees = top-left to bottom-right)
        gradient?.draw(in: bounds, angle: -45)
        
        // Add subtle noise texture overlay for depth
        let overlayColor = NSColor.black.withAlphaComponent(0.05)
        overlayColor.setFill()
        bounds.fill()
    }
    
    override func updateLayer() {
        // Ensure corner radius is maintained
        layer?.cornerRadius = 12
    }
}

// MARK: - Window Drag View

class WindowDragView: NSView {
    
    private var initialLocation: NSPoint?
    
    override func mouseDown(with event: NSEvent) {
        initialLocation = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window, let initialLocation = initialLocation else { return }
        
        let currentLocation = event.locationInWindow
        let newOrigin = NSPoint(
            x: window.frame.origin.x + (currentLocation.x - initialLocation.x),
            y: window.frame.origin.y + (currentLocation.y - initialLocation.y)
        )
        window.setFrameOrigin(newOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        initialLocation = nil
        
        // Double-click to maximize/restore
        if event.clickCount == 2 {
            guard let window = self.window else { return }
            window.zoom(nil)
        }
    }
}
