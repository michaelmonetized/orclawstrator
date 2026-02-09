import Cocoa

/// Main content area containing embedded sidebar and dashboard/detail view
/// Sidebar is NOT a native AppKit sidebar - just a left column
class MainContentView: NSView {
    
    // MARK: - UI Components

    private var sidebarView: EmbeddedSidebarView!
    private var contentContainer: NSView!
    private var dashboardView: DashboardView!
    private var detailViewController: ProjectDetailViewController?
    private var inboxView: InboxView?
    
    // MARK: - External References
    
    var topStatusBar: TopStatusBar?
    var onProjectSelected: ((Project) -> Void)?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Embedded sidebar (left column, 240px width)
        sidebarView = EmbeddedSidebarView()
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sidebarView)
        
        // Vertical divider
        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = Catppuccin.surface1.withAlphaComponent(0.3).cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(divider)
        
        // Content container (right side - dashboard or detail)
        contentContainer = NSView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentContainer)
        
        // Dashboard view (default content)
        dashboardView = DashboardView()
        dashboardView.translatesAutoresizingMaskIntoConstraints = false
        dashboardView.onProjectSelected = { [weak self] project in
            self?.onProjectSelected?(project)
        }
        contentContainer.addSubview(dashboardView)

        // Wire up inbox callback
        sidebarView.onInboxSelected = { [weak self] in
            self?.showInbox()
        }

        // Wire up new project callback
        sidebarView.onNewProjectCreated = { [weak self] project in
            self?.onProjectSelected?(project)
        }
        
        NSLayoutConstraint.activate([
            // Sidebar on left
            sidebarView.topAnchor.constraint(equalTo: topAnchor),
            sidebarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sidebarView.widthAnchor.constraint(equalToConstant: 240),
            
            // Divider
            divider.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            divider.leadingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1),
            
            // Content container
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Dashboard fills content container
            dashboardView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            dashboardView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            dashboardView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            dashboardView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        
        // Connect dashboard to top status bar
        dashboardView.topStatusBar = topStatusBar
    }
    
    // MARK: - Navigation
    
    func showProjectDetail(_ project: Project) {
        // Hide dashboard
        dashboardView.isHidden = true
        
        // Remove old detail view if any
        detailViewController?.view.removeFromSuperview()
        
        // Create and add detail view
        let detailVC = ProjectDetailViewController()
        detailVC.configure(with: project)
        detailVC.onBack = { [weak self] in
            self?.showDashboard()
        }
        detailVC.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(detailVC.view)
        
        NSLayoutConstraint.activate([
            detailVC.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            detailVC.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            detailVC.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            detailVC.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        
        detailViewController = detailVC
    }
    
    func showDashboard() {
        // Remove detail view
        detailViewController?.view.removeFromSuperview()
        detailViewController = nil

        // Remove inbox view
        inboxView?.removeFromSuperview()
        inboxView = nil

        // Show dashboard
        dashboardView.isHidden = false

        // Refresh dashboard
        dashboardView.refreshProjects()
    }

    func showInbox() {
        // Hide dashboard
        dashboardView.isHidden = true

        // Remove detail view if any
        detailViewController?.view.removeFromSuperview()
        detailViewController = nil

        // Remove old inbox view if any
        inboxView?.removeFromSuperview()

        // Create and add inbox view
        let inbox = InboxView()
        inbox.translatesAutoresizingMaskIntoConstraints = false
        inbox.onBack = { [weak self] in
            self?.showDashboard()
        }
        contentContainer.addSubview(inbox)

        NSLayoutConstraint.activate([
            inbox.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            inbox.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            inbox.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            inbox.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        inboxView = inbox
    }
    
    // Forward top status bar reference
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        dashboardView?.topStatusBar = topStatusBar
    }
}

// MARK: - Embedded Sidebar View

class EmbeddedSidebarView: NSView {

    // MARK: - UI Components

    private var chatInputContainer: NSView!
    private var chatInputField: NSTextField!
    private var sendButton: NSButton!
    private var inboxButton: NSButton!
    private var newProjectButton: NSButton!
    private var recentChatsLabel: NSTextField!
    private var recentChatsScrollView: NSScrollView!
    private var recentChatsTableView: NSTableView!
    private var inboxBadge: NSTextField!

    // MARK: - Callbacks

    var onInboxSelected: (() -> Void)?
    var onNewProjectCreated: ((Project) -> Void)?
    
    // MARK: - Services
    
    private let openClawService = OpenClawService.shared
    private let database = DatabaseManager.shared
    
    // MARK: - Data
    
    private var recentChats: [(title: String, subtitle: String?)] = []
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadRecentChats()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadRecentChats()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = Catppuccin.crust.withAlphaComponent(0.5).cgColor
        
        // Chat input container at top
        chatInputContainer = NSView()
        chatInputContainer.wantsLayer = true
        chatInputContainer.layer?.backgroundColor = Catppuccin.surface0.withAlphaComponent(0.6).cgColor
        chatInputContainer.layer?.cornerRadius = 8
        chatInputContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chatInputContainer)
        
        // Chat input field
        chatInputField = NSTextField()
        chatInputField.placeholderString = "Chat with openclaw..."
        chatInputField.isBezeled = false
        chatInputField.drawsBackground = false
        chatInputField.textColor = Catppuccin.text
        chatInputField.focusRingType = .none
        chatInputField.font = NSFont.systemFont(ofSize: 12)
        chatInputField.translatesAutoresizingMaskIntoConstraints = false
        chatInputField.delegate = self
        chatInputContainer.addSubview(chatInputField)
        
        // Send button
        sendButton = NSButton(title: "↵", target: self, action: #selector(sendMessage))
        sendButton.bezelStyle = .inline
        sendButton.isBordered = false
        sendButton.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        sendButton.contentTintColor = Catppuccin.teal
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        chatInputContainer.addSubview(sendButton)
        
        // Inbox button with badge
        let inboxContainer = NSView()
        inboxContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inboxContainer)

        inboxButton = NSButton(title: "📥 Inbox", target: self, action: #selector(inboxClicked))
        inboxButton.bezelStyle = .rounded
        inboxButton.contentTintColor = Catppuccin.blue
        inboxButton.translatesAutoresizingMaskIntoConstraints = false
        inboxContainer.addSubview(inboxButton)

        inboxBadge = NSTextField(labelWithString: "")
        inboxBadge.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        inboxBadge.textColor = .white
        inboxBadge.backgroundColor = Catppuccin.red
        inboxBadge.wantsLayer = true
        inboxBadge.layer?.backgroundColor = Catppuccin.red.cgColor
        inboxBadge.layer?.cornerRadius = 8
        inboxBadge.alignment = .center
        inboxBadge.translatesAutoresizingMaskIntoConstraints = false
        inboxBadge.isHidden = true
        inboxContainer.addSubview(inboxBadge)

        NSLayoutConstraint.activate([
            inboxButton.leadingAnchor.constraint(equalTo: inboxContainer.leadingAnchor),
            inboxButton.trailingAnchor.constraint(equalTo: inboxContainer.trailingAnchor),
            inboxButton.topAnchor.constraint(equalTo: inboxContainer.topAnchor),
            inboxButton.bottomAnchor.constraint(equalTo: inboxContainer.bottomAnchor),

            inboxBadge.trailingAnchor.constraint(equalTo: inboxContainer.trailingAnchor, constant: 4),
            inboxBadge.topAnchor.constraint(equalTo: inboxContainer.topAnchor, constant: -4),
            inboxBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            inboxBadge.heightAnchor.constraint(equalToConstant: 16)
        ])

        // New Project button
        newProjectButton = NSButton(title: "+ New Project", target: self, action: #selector(newProjectClicked))
        newProjectButton.bezelStyle = .rounded
        newProjectButton.contentTintColor = Catppuccin.teal
        newProjectButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(newProjectButton)

        // Update inbox badge
        updateInboxBadge()
        
        // Recent Chats section header
        recentChatsLabel = NSTextField(labelWithString: "Recent Chats")
        recentChatsLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        recentChatsLabel.textColor = Catppuccin.subtext0
        recentChatsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recentChatsLabel)
        
        // Recent chats list
        setupRecentChatsList()
        
        // Layout
        NSLayoutConstraint.activate([
            // Chat input container
            chatInputContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            chatInputContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            chatInputContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            chatInputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Chat input field
            chatInputField.topAnchor.constraint(equalTo: chatInputContainer.topAnchor, constant: 10),
            chatInputField.leadingAnchor.constraint(equalTo: chatInputContainer.leadingAnchor, constant: 10),
            chatInputField.trailingAnchor.constraint(equalTo: chatInputContainer.trailingAnchor, constant: -10),
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: chatInputContainer.trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: chatInputContainer.bottomAnchor, constant: -8),
            
            // Inbox button
            inboxContainer.topAnchor.constraint(equalTo: chatInputContainer.bottomAnchor, constant: 12),
            inboxContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            inboxContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            // New Project button
            newProjectButton.topAnchor.constraint(equalTo: inboxContainer.bottomAnchor, constant: 8),
            newProjectButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            newProjectButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            // Recent Chats label
            recentChatsLabel.topAnchor.constraint(equalTo: newProjectButton.bottomAnchor, constant: 20),
            recentChatsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Recent chats scroll view
            recentChatsScrollView.topAnchor.constraint(equalTo: recentChatsLabel.bottomAnchor, constant: 8),
            recentChatsScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            recentChatsScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            recentChatsScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func setupRecentChatsList() {
        recentChatsScrollView = NSScrollView()
        recentChatsScrollView.translatesAutoresizingMaskIntoConstraints = false
        recentChatsScrollView.hasVerticalScroller = true
        recentChatsScrollView.autohidesScrollers = true
        recentChatsScrollView.borderType = .noBorder
        recentChatsScrollView.drawsBackground = false
        addSubview(recentChatsScrollView)
        
        recentChatsTableView = NSTableView()
        recentChatsTableView.headerView = nil
        recentChatsTableView.backgroundColor = .clear
        recentChatsTableView.rowHeight = 44
        recentChatsTableView.intercellSpacing = NSSize(width: 0, height: 4)
        recentChatsTableView.delegate = self
        recentChatsTableView.dataSource = self
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("chat"))
        column.width = 220
        recentChatsTableView.addTableColumn(column)
        
        recentChatsScrollView.documentView = recentChatsTableView
    }
    
    private func loadRecentChats() {
        // Get from database - no fake data
        recentChats = database.getRecentChats(limit: 10)

        // Also try to get sessions from OpenClaw
        openClawService.getSessions { [weak self] sessions in
            guard let self = self else { return }

            if !sessions.isEmpty {
                self.recentChats = sessions.prefix(10).map { session in
                    let subtitle = session.status + (session.tokensUsed.map { " • \($0) tokens" } ?? "")
                    return (title: session.label ?? session.id, subtitle: subtitle)
                }
                self.recentChatsTableView.reloadData()
            }
        }

        recentChatsTableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func sendMessage() {
        let message = chatInputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        openClawService.sendMessage(message, to: "main") { [weak self] success in
            if success {
                // Save to recent chats
                self?.database.saveRecentChat(title: message, subtitle: nil, projectPath: nil)
                self?.loadRecentChats()
            }
        }
        
        chatInputField.stringValue = ""
    }
    
    @objc private func newProjectClicked() {
        // Show dialog to get project name
        let alert = NSAlert()
        alert.messageText = "New Project"
        alert.informativeText = "Enter a name for your new project:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.placeholderString = "my-awesome-project"
        alert.accessoryView = inputField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let projectName = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectName.isEmpty else {
            ErrorBanner.shared.showError("Project name cannot be empty")
            return
        }

        // Create the project folder in ~/Projects
        let projectsDir = NSString(string: "~/Projects").expandingTildeInPath
        let projectPath = (projectsDir as NSString).appendingPathComponent(projectName)

        let fileManager = FileManager.default

        // Check if folder already exists
        if fileManager.fileExists(atPath: projectPath) {
            ErrorBanner.shared.showWarning("A project with that name already exists")
            return
        }

        do {
            // Create project directory
            try fileManager.createDirectory(atPath: projectPath, withIntermediateDirectories: true)

            // Initialize git repo
            let shell = ShellExecutor.shared
            _ = shell.run("git init", in: projectPath)

            // Create initial README
            let readme = "# \(projectName)\n\nDescribe your project here.\n"
            try readme.write(toFile: (projectPath as NSString).appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

            // Create a Project object for the new project
            let project = Project(name: projectName, path: projectPath)
            project.language = .terminal
            project.gitState = GitService.shared.getGitState(for: projectPath)

            ErrorBanner.shared.showSuccess("Created project: \(projectName)")

            // Navigate to the new project
            onNewProjectCreated?(project)

        } catch {
            ErrorBanner.shared.showError("Failed to create project: \(error.localizedDescription)")
        }
    }

    @objc private func inboxClicked() {
        onInboxSelected?()
    }

    private func updateInboxBadge() {
        let unreadCount = database.getUnreadMessageCount()
        if unreadCount > 0 {
            inboxBadge.stringValue = unreadCount > 99 ? "99+" : "\(unreadCount)"
            inboxBadge.isHidden = false
        } else {
            inboxBadge.isHidden = true
        }
    }

    func refreshBadge() {
        updateInboxBadge()
    }
}

// MARK: - NSTextFieldDelegate

extension EmbeddedSidebarView: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            sendMessage()
            return true
        }
        return false
    }
}

// MARK: - NSTableViewDataSource

extension EmbeddedSidebarView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return recentChats.count
    }
}

// MARK: - NSTableViewDelegate

extension EmbeddedSidebarView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < recentChats.count else { return nil }
        let chat = recentChats[row]
        
        let cell = NSView()
        cell.wantsLayer = true
        cell.layer?.backgroundColor = Catppuccin.surface0.withAlphaComponent(0.3).cgColor
        cell.layer?.cornerRadius = 6
        
        let titleLabel = NSTextField(labelWithString: chat.title)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = Catppuccin.text
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(titleLabel)
        
        let subtitleLabel = NSTextField(labelWithString: chat.subtitle ?? "")
        subtitleLabel.font = NSFont.systemFont(ofSize: 10)
        subtitleLabel.textColor = Catppuccin.subtext0
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10)
        ])
        
        return cell
    }
}
