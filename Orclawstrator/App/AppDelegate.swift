import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController!
    var quickSwitcher: QuickSwitcherPanel?
    var statusItem: NSStatusItem?
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create main window controller
        windowController = MainWindowController()
        windowController.showWindow(nil)

        // Setup menu bar
        setupMenuBar()

        // Setup keyboard shortcuts
        setupKeyboardShortcuts()

        // Setup status bar item
        setupStatusBarItem()

        // Activate app
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // App menu
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Orclawstrator", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Orclawstrator", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Save", action: #selector(saveDocument(_:)), keyEquivalent: "s")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Refresh", action: #selector(refreshDashboard), keyEquivalent: "r")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu (standard editing commands)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Dashboard", action: #selector(showDashboard), keyEquivalent: "1")
        viewMenu.addItem(withTitle: "Inbox", action: #selector(showInbox), keyEquivalent: "i")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Quick Switcher", action: #selector(showQuickSwitcher), keyEquivalent: "k")

        let viewMenuItem = NSMenuItem()
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Go menu for project shortcuts
        let goMenu = NSMenu(title: "Go")
        for i in 1...9 {
            let item = NSMenuItem(title: "Project \(i)", action: #selector(goToProject(_:)), keyEquivalent: "\(i)")
            item.tag = i - 1
            goMenu.addItem(item)
        }

        let goMenuItem = NSMenuItem()
        goMenuItem.submenu = goMenu
        mainMenu.addItem(goMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Keyboard Shortcuts

    private func setupKeyboardShortcuts() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Escape key to go back to dashboard
            if event.keyCode == 53 && !event.modifierFlags.contains(.command) {
                if self?.quickSwitcher?.isVisible == true {
                    self?.quickSwitcher?.hide()
                    return nil
                }
                self?.showDashboard()
                return nil
            }
            return event
        }
    }

    // MARK: - Status Bar Item

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Orclawstrator")
            button.action = #selector(statusBarClicked)
            button.target = self
        }

        // Create status bar menu
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Orclawstrator", action: #selector(showMainWindow), keyEquivalent: "")
        menu.addItem(withTitle: "Quick Switcher", action: #selector(showQuickSwitcher), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        let unreadCount = DatabaseManager.shared.getUnreadMessageCount()
        if unreadCount > 0 {
            menu.addItem(withTitle: "Inbox (\(unreadCount) unread)", action: #selector(showInbox), keyEquivalent: "")
        } else {
            menu.addItem(withTitle: "Inbox", action: #selector(showInbox), keyEquivalent: "")
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Refresh", action: #selector(refreshDashboard), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func statusBarClicked() {
        showMainWindow()
    }

    @objc private func showMainWindow() {
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Orclawstrator"
        alert.informativeText = "Native macOS command center for orchestrating AI coding agents.\n\nVersion 1.0"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc private func refreshDashboard() {
        windowController.refreshDashboard()
    }

    @objc private func saveDocument(_ sender: Any?) {
        // Post notification for any view that wants to handle save
        NotificationCenter.default.post(name: NSNotification.Name("SaveDocument"), object: nil)
    }

    @objc private func showDashboard() {
        windowController.showDashboard()
    }

    @objc private func showInbox() {
        windowController.showInbox()
    }

    @objc private func showQuickSwitcher() {
        if quickSwitcher == nil {
            quickSwitcher = QuickSwitcherPanel(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                styleMask: [],
                backing: .buffered,
                defer: false
            )
            quickSwitcher?.onProjectSelected = { [weak self] project in
                self?.windowController.showProjectDetail(project)
            }
        }

        let projects = windowController.getProjects()
        quickSwitcher?.show(with: projects)
    }

    @objc private func goToProject(_ sender: NSMenuItem) {
        let index = sender.tag
        let projects = windowController.getProjects()
        if index < projects.count {
            windowController.showProjectDetail(projects[index])
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
