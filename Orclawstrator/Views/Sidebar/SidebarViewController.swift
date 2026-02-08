import Cocoa

class SidebarViewController: NSViewController {
    
    // MARK: - UI Components
    private var logoLabel: NSTextField!
    private var chatInputField: NSTextField!
    private var sendButton: NSButton!
    private var newProjectButton: NSButton!
    private var recentChatsScrollView: NSScrollView!
    private var recentChatsOutlineView: NSOutlineView!
    private var statusView: StatusBarView!
    
    // MARK: - Services
    private let openClawService = OpenClawService.shared
    
    // MARK: - Data
    private var recentChats: [RecentChat] = [
        RecentChat(title: "orclawstrator", subtitle: "Building the dashboard..."),
        RecentChat(title: "openclaw", subtitle: "Added browser automation"),
        RecentChat(title: "dotfiles", subtitle: "Configured neovim LSP")
    ]
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 800))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConnectionObserver()
        loadRecentSessions()
    }
    
    private func setupConnectionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectionChange(_:)),
            name: NSNotification.Name("OpenClawConnectionChanged"),
            object: nil
        )
        
        // Update initial status
        statusView.setConnected(openClawService.isConnected)
        statusView.setStatus(openClawService.isConnected ? "Connected | Idle | agent main" : "Disconnected")
    }
    
    @objc private func handleConnectionChange(_ notification: Notification) {
        guard let connected = notification.userInfo?["connected"] as? Bool else { return }
        statusView.setConnected(connected)
        statusView.setStatus(connected ? "Connected | Idle | agent main" : "Disconnected")
    }
    
    private func loadRecentSessions() {
        // Get sessions from OpenClaw
        openClawService.getSessions { [weak self] sessions in
            guard let self = self else { return }
            
            // Convert to recent chats
            self.recentChats = sessions.prefix(10).map { session in
                RecentChat(
                    title: session.label ?? session.id,
                    subtitle: session.status + (session.tokensUsed.map { " • \($0) tokens" } ?? "")
                )
            }
            
            // Add placeholder if empty
            if self.recentChats.isEmpty {
                self.recentChats = [
                    RecentChat(title: "No active sessions", subtitle: "Start chatting to begin")
                ]
            }
            
            self.recentChatsOutlineView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = Catppuccin.crust.cgColor
        
        // Logo/Title
        logoLabel = NSTextField(labelWithString: "🦞 Orclawstrator")
        logoLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        logoLabel.textColor = Catppuccin.text
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoLabel)
        
        // Chat input area
        let chatContainer = createChatInputArea()
        chatContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatContainer)
        
        // New Project button
        newProjectButton = NSButton(title: "+ New Project", target: self, action: #selector(newProjectClicked))
        newProjectButton.bezelStyle = .rounded
        newProjectButton.translatesAutoresizingMaskIntoConstraints = false
        newProjectButton.contentTintColor = Catppuccin.teal
        view.addSubview(newProjectButton)
        
        // Recent Chats section
        let recentLabel = NSTextField(labelWithString: "RECENT CHATS")
        recentLabel.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        recentLabel.textColor = Catppuccin.overlay0
        recentLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recentLabel)
        
        // Recent chats list
        setupRecentChatsList()
        view.addSubview(recentChatsScrollView)
        
        // Status bar at bottom
        statusView = StatusBarView()
        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Logo
            logoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Chat input
            chatContainer.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 20),
            chatContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            chatContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            chatContainer.heightAnchor.constraint(equalToConstant: 80),
            
            // New Project button
            newProjectButton.topAnchor.constraint(equalTo: chatContainer.bottomAnchor, constant: 12),
            newProjectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            newProjectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            // Recent label
            recentLabel.topAnchor.constraint(equalTo: newProjectButton.bottomAnchor, constant: 20),
            recentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Recent chats list
            recentChatsScrollView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: 8),
            recentChatsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            recentChatsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            recentChatsScrollView.bottomAnchor.constraint(equalTo: statusView.topAnchor, constant: -8),
            
            // Status bar
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func createChatInputArea() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = Catppuccin.surface0.cgColor
        container.layer?.cornerRadius = 8
        
        // Text field
        chatInputField = NSTextField()
        chatInputField.placeholderString = "Message OpenClaw..."
        chatInputField.isBezeled = false
        chatInputField.drawsBackground = false
        chatInputField.textColor = Catppuccin.text
        chatInputField.focusRingType = .none
        chatInputField.font = NSFont.systemFont(ofSize: 13)
        chatInputField.translatesAutoresizingMaskIntoConstraints = false
        chatInputField.delegate = self
        container.addSubview(chatInputField)
        
        // Send button
        sendButton = NSButton(title: "↵", target: self, action: #selector(sendMessage))
        sendButton.bezelStyle = .inline
        sendButton.isBordered = false
        sendButton.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        sendButton.contentTintColor = Catppuccin.teal
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            chatInputField.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            chatInputField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            chatInputField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            chatInputField.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    private func setupRecentChatsList() {
        recentChatsScrollView = NSScrollView()
        recentChatsScrollView.translatesAutoresizingMaskIntoConstraints = false
        recentChatsScrollView.hasVerticalScroller = true
        recentChatsScrollView.autohidesScrollers = true
        recentChatsScrollView.borderType = .noBorder
        recentChatsScrollView.drawsBackground = false
        
        recentChatsOutlineView = NSOutlineView()
        recentChatsOutlineView.headerView = nil
        recentChatsOutlineView.backgroundColor = .clear
        recentChatsOutlineView.rowHeight = 44
        recentChatsOutlineView.indentationPerLevel = 0
        recentChatsOutlineView.delegate = self
        recentChatsOutlineView.dataSource = self
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("chat"))
        column.width = 220
        recentChatsOutlineView.addTableColumn(column)
        recentChatsOutlineView.outlineTableColumn = column
        
        recentChatsScrollView.documentView = recentChatsOutlineView
    }
    
    // MARK: - Actions
    @objc private func sendMessage() {
        let message = chatInputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        // Send to OpenClaw Gateway
        openClawService.sendMessage(message, to: "main") { [weak self] success in
            if success {
                // Reload sessions to show updated activity
                self?.loadRecentSessions()
            } else {
                // Show error
                self?.statusView.setStatus("Failed to send message")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.statusView.setStatus(self?.openClawService.isConnected == true ? "Connected | Idle" : "Disconnected")
                }
            }
        }
        
        chatInputField.stringValue = ""
    }
    
    @objc private func newProjectClicked() {
        print("New project clicked")
        // TODO: Show new project dialog
    }
}

// MARK: - NSTextFieldDelegate

extension SidebarViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            sendMessage()
            return true
        }
        return false
    }
}

// MARK: - NSOutlineViewDataSource

extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? recentChats.count : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return recentChats[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}

// MARK: - NSOutlineViewDelegate

extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let chat = item as? RecentChat else { return nil }
        
        let cell = NSView()
        
        let titleLabel = NSTextField(labelWithString: chat.title)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = Catppuccin.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(titleLabel)
        
        let subtitleLabel = NSTextField(labelWithString: chat.subtitle)
        subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = Catppuccin.subtext0
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8)
        ])
        
        return cell
    }
}

// MARK: - RecentChat Model

struct RecentChat {
    let title: String
    let subtitle: String
}

// MARK: - Status Bar View

class StatusBarView: NSView {
    
    private var statusDot: NSView!
    private var statusLabel: NSTextField!
    private var modelLabel: NSTextField!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = Catppuccin.mantle.cgColor
        
        // Status indicator dot
        statusDot = NSView()
        statusDot.wantsLayer = true
        statusDot.layer?.backgroundColor = Catppuccin.green.cgColor
        statusDot.layer?.cornerRadius = 4
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusDot)
        
        // Status text
        statusLabel = NSTextField(labelWithString: "Connected | Idle | agent main")
        statusLabel.font = NSFont.systemFont(ofSize: 10)
        statusLabel.textColor = Catppuccin.subtext0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        // Model label
        modelLabel = NSTextField(labelWithString: "claude-opus-4-5")
        modelLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        modelLabel.textColor = Catppuccin.overlay1
        modelLabel.alignment = .right
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(modelLabel)
        
        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            statusDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            modelLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            modelLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func setConnected(_ connected: Bool) {
        statusDot.layer?.backgroundColor = connected ? Catppuccin.green.cgColor : Catppuccin.red.cgColor
    }
    
    func setStatus(_ status: String) {
        statusLabel.stringValue = status
    }
}
