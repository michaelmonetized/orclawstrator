import Cocoa
import SwiftTerm

/// Project detail view with split pane: markdown viewer + agent activity
class ProjectDetailViewController: NSViewController {
    
    // MARK: - Properties
    
    private var project: Project?
    private let openClawService = OpenClawService.shared
    
    // MARK: - UI Components
    
    private var splitView: NSSplitView!
    private var markdownPanel: MarkdownPanelView!
    private var activityPanel: AgentActivityView!
    private var headerView: ProjectHeaderView!
    
    // MARK: - Callbacks
    
    var onBack: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
    }
    
    // MARK: - Configuration
    
    func configure(with project: Project) {
        self.project = project
        headerView?.configure(with: project)
        markdownPanel?.loadProject(project)
        activityPanel?.setProjectPath(project.path)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Header with back button and project info
        headerView = ProjectHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.onBack = { [weak self] in self?.onBack?() }
        view.addSubview(headerView)
        
        // Split view for markdown + activity
        splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitView)
        
        // Markdown panel (left)
        markdownPanel = MarkdownPanelView()
        splitView.addSubview(markdownPanel)
        
        // Activity panel (right)
        activityPanel = AgentActivityView()
        splitView.addSubview(activityPanel)
        
        // Layout
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),
            
            splitView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            splitView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            splitView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            splitView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        // Set initial split position
        DispatchQueue.main.async { [weak self] in
            self?.splitView.setPosition((self?.view.bounds.width ?? 1000) * 0.5, ofDividerAt: 0)
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAgentMessage(_:)),
            name: NSNotification.Name("AgentMessageReceived"),
            object: nil
        )
    }
    
    @objc private func handleAgentMessage(_ notification: Notification) {
        guard let message = notification.userInfo?["message"] as? OpenClawService.AgentMessage else { return }
        activityPanel?.appendMessage(message)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Project Header View

class ProjectHeaderView: NSView {

    private var backButton: NSButton!
    private var titleLabel: NSTextField!
    private var pathLabel: NSTextField!
    private var languageIcon: NSTextField!
    private var branchPopup: NSPopUpButton!
    private var statusPills: NSStackView!
    private var currentProject: Project?

    var onBack: (() -> Void)?
    var onBranchChange: ((String) -> Void)?
    
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
        layer?.backgroundColor = Catppuccin.surface0.withAlphaComponent(0.6).cgColor
        
        // Back button
        backButton = NSButton(title: "←", target: self, action: #selector(backClicked))
        backButton.bezelStyle = .inline
        backButton.isBordered = false
        backButton.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        backButton.contentTintColor = Catppuccin.text
        backButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backButton)
        
        // Language icon
        languageIcon = NSTextField(labelWithString: "🖥️")
        languageIcon.font = NSFont.systemFont(ofSize: 24)
        languageIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(languageIcon)
        
        // Title
        titleLabel = NSTextField(labelWithString: "Project")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Catppuccin.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Path
        pathLabel = NSTextField(labelWithString: "~/Projects/...")
        pathLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        pathLabel.textColor = Catppuccin.subtext0
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pathLabel)

        // Branch popup
        branchPopup = NSPopUpButton()
        branchPopup.font = NSFont.systemFont(ofSize: 11)
        branchPopup.target = self
        branchPopup.action = #selector(branchSelected)
        branchPopup.translatesAutoresizingMaskIntoConstraints = false
        addSubview(branchPopup)

        // Status pills
        statusPills = NSStackView()
        statusPills.orientation = .horizontal
        statusPills.spacing = 8
        statusPills.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusPills)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            
            languageIcon.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            languageIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: languageIcon.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            
            pathLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            pathLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            branchPopup.leadingAnchor.constraint(equalTo: pathLabel.trailingAnchor, constant: 12),
            branchPopup.centerYAnchor.constraint(equalTo: pathLabel.centerYAnchor),
            branchPopup.widthAnchor.constraint(lessThanOrEqualToConstant: 200),

            statusPills.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            statusPills.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with project: Project) {
        currentProject = project
        titleLabel.stringValue = project.name
        pathLabel.stringValue = project.path
        languageIcon.stringValue = project.language.icon

        // Populate branch popup
        branchPopup.removeAllItems()
        for branch in project.gitState.branches {
            branchPopup.addItem(withTitle: branch)
        }
        // Select current branch
        if let index = project.gitState.branches.firstIndex(of: project.gitState.activeBranch) {
            branchPopup.selectItem(at: index)
        }

        // Clear and rebuild status pills
        statusPills.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Git status
        if project.gitState.untracked > 0 {
            statusPills.addArrangedSubview(createPill("\(project.gitState.untracked) untracked", color: Catppuccin.red))
        }
        if project.gitState.staged > 0 {
            statusPills.addArrangedSubview(createPill("\(project.gitState.staged) staged", color: Catppuccin.green))
        }
        
        // Build status
        switch project.buildStatus {
        case .ready:
            statusPills.addArrangedSubview(createPill("Ready", color: Catppuccin.green))
        case .building:
            statusPills.addArrangedSubview(createPill("Building", color: Catppuccin.peach))
        case .error:
            statusPills.addArrangedSubview(createPill("Error", color: Catppuccin.red))
        default:
            break
        }
    }
    
    private func createPill(_ text: String, color: NSColor) -> NSView {
        let pill = NSView()
        pill.wantsLayer = true
        pill.layer?.backgroundColor = color.withAlphaComponent(0.2).cgColor
        pill.layer?.cornerRadius = 10
        pill.layer?.borderWidth = 1
        pill.layer?.borderColor = color.withAlphaComponent(0.4).cgColor
        
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -4)
        ])
        
        return pill
    }
    
    @objc private func backClicked() {
        onBack?()
    }

    @objc private func branchSelected() {
        guard let project = currentProject,
              let selectedBranch = branchPopup.titleOfSelectedItem,
              selectedBranch != project.gitState.activeBranch else { return }

        // Checkout the branch
        let projectPath = (project.path as NSString).expandingTildeInPath
        let shell = ShellExecutor.shared
        let result = shell.run("git checkout \(selectedBranch)", in: projectPath)

        if result.exitCode == 0 {
            onBranchChange?(selectedBranch)
        } else {
            // Revert popup to current branch
            if let index = project.gitState.branches.firstIndex(of: project.gitState.activeBranch) {
                branchPopup.selectItem(at: index)
            }
            print("[Git] Failed to checkout branch: \(result.output)")
        }
    }
}

// MARK: - Markdown Panel View (Embedded Terminal with nvim)

class MarkdownPanelView: NSView {

    private var tabBar: NSSegmentedControl!
    private var terminalView: EmbeddedTerminalView!
    private var statusLabel: NSTextField!
    private var currentProject: Project?
    private var currentFilePath: String?

    private let tabFiles = ["README.md", "PLAN.md", "ROADMAP.md", "CHANGELOG.md"]

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
        layer?.backgroundColor = Catppuccin.base.cgColor
        layer?.cornerRadius = 8

        // Tab bar
        tabBar = NSSegmentedControl(labels: ["README", "PLAN", "ROADMAP", "CHANGELOG"], trackingMode: .selectOne, target: self, action: #selector(tabChanged))
        tabBar.selectedSegment = 0
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabBar)

        // Status label
        statusLabel = NSTextField(labelWithString: "nvim")
        statusLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        statusLabel.textColor = Catppuccin.green
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)

        // Terminal view for nvim
        terminalView = EmbeddedTerminalView()
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(terminalView)

        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            tabBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            statusLabel.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            terminalView.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: 8),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func loadProject(_ project: Project) {
        currentProject = project
        loadCurrentTab()
    }

    @objc private func tabChanged() {
        loadCurrentTab()
    }

    private func loadCurrentTab() {
        guard let project = currentProject else { return }

        let filename = tabFiles[tabBar.selectedSegment]

        var projectPath = project.path
        if projectPath.hasPrefix("~") {
            projectPath = (projectPath as NSString).expandingTildeInPath
        }
        let filePath = (projectPath as NSString).appendingPathComponent(filename)

        currentFilePath = filePath
        statusLabel.stringValue = "nvim \(filename)"

        // Create file if it doesn't exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath) {
            let template = createTemplate(for: filename, projectName: project.name)
            try? template.write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        // Launch nvim in the terminal view
        terminalView.runCommand("nvim '\(filePath)'", workingDirectory: projectPath)
    }

    private func createTemplate(for filename: String, projectName: String) -> String {
        switch filename {
        case "README.md":
            return "# \(projectName)\n\nDescribe your project here.\n"
        case "PLAN.md":
            return "# \(projectName) - Plan\n\n## Goals\n\n- [ ] Goal 1\n"
        case "ROADMAP.md":
            return "# \(projectName) - Roadmap\n\n## v1.0\n\n- [ ] Feature 1\n"
        case "CHANGELOG.md":
            return "# Changelog\n\n## [Unreleased]\n\n### Added\n- Initial setup\n"
        default:
            return "# \(filename)\n"
        }
    }
}

// MARK: - Terminal View (SwiftTerm-based terminal emulator)

class EmbeddedTerminalView: NSView, LocalProcessTerminalViewDelegate {

    private var terminalView: LocalProcessTerminalView!
    private var currentWorkingDirectory: String = ""
    private var currentCommand: String = ""

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
        layer?.backgroundColor = Catppuccin.base.cgColor

        // Create SwiftTerm terminal view
        terminalView = LocalProcessTerminalView(frame: bounds)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        terminalView.processDelegate = self

        // Configure terminal appearance
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminalView.nativeForegroundColor = Catppuccin.text
        terminalView.nativeBackgroundColor = Catppuccin.base

        // Set Catppuccin color palette
        configureCatppuccinPalette()

        addSubview(terminalView)

        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureCatppuccinPalette() {
        // Catppuccin Macchiato palette for terminal - use SwiftTerm Color
        func toColor(_ c: NSColor) -> Color {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            return Color(red: UInt16(r * 65535), green: UInt16(g * 65535), blue: UInt16(b * 65535))
        }

        let palette: [Color] = [
            toColor(Catppuccin.surface1),      // 0: black
            toColor(Catppuccin.red),           // 1: red
            toColor(Catppuccin.green),         // 2: green
            toColor(Catppuccin.yellow),        // 3: yellow
            toColor(Catppuccin.blue),          // 4: blue
            toColor(Catppuccin.pink),          // 5: magenta
            toColor(Catppuccin.teal),          // 6: cyan
            toColor(Catppuccin.subtext1),      // 7: white
            toColor(Catppuccin.overlay0),      // 8: bright black
            toColor(Catppuccin.red),           // 9: bright red
            toColor(Catppuccin.green),         // 10: bright green
            toColor(Catppuccin.yellow),        // 11: bright yellow
            toColor(Catppuccin.blue),          // 12: bright blue
            toColor(Catppuccin.pink),          // 13: bright magenta
            toColor(Catppuccin.sky),           // 14: bright cyan
            toColor(Catppuccin.text)           // 15: bright white
        ]
        terminalView.installColors(palette)
    }

    func runCommand(_ command: String, workingDirectory: String) {
        currentWorkingDirectory = workingDirectory
        currentCommand = command

        // Set environment for proper terminal behavior
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["LANG"] = "en_US.UTF-8"
        env["LC_ALL"] = "en_US.UTF-8"
        env["HOME"] = NSHomeDirectory()
        env["SHELL"] = "/bin/zsh"

        // Start the process with nvim or shell command
        terminalView.startProcess(
            executable: "/bin/zsh",
            args: ["-c", command],
            environment: Array(env.map { "\($0.key)=\($0.value)" }),
            execName: "zsh"
        )
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        // Terminal size changed - SwiftTerm handles this automatically
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        // Could update tab title here if needed
    }

    func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
        if let dir = directory {
            currentWorkingDirectory = dir
        }
    }

    func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
        // Process ended - could notify parent view
        DispatchQueue.main.async { [weak self] in
            self?.terminalView.feed(text: "\r\n[Process exited with code \(exitCode ?? -1)]\r\n")
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        return terminalView.becomeFirstResponder()
    }
}

// MARK: - Agent Activity View

class AgentActivityView: NSView {
    
    private var headerLabel: NSTextField!
    private var scrollView: NSScrollView!
    private var textView: NSTextView!
    private var inputField: NSTextField!
    private var sendButton: NSButton!
    
    private var projectPath: String?
    private let openClawService = OpenClawService.shared
    
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
        layer?.backgroundColor = Catppuccin.crust.withAlphaComponent(0.7).cgColor
        layer?.cornerRadius = 8
        
        // Header
        headerLabel = NSTextField(labelWithString: "🤖 Agent Activity")
        headerLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        headerLabel.textColor = Catppuccin.text
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)
        
        // Activity scroll view
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textColor = Catppuccin.text
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.autoresizingMask = [.width]
        textView.isAutomaticLinkDetectionEnabled = true
        
        scrollView.documentView = textView
        
        // Input area
        let inputContainer = NSView()
        inputContainer.wantsLayer = true
        inputContainer.layer?.backgroundColor = Catppuccin.surface0.withAlphaComponent(0.6).cgColor
        inputContainer.layer?.cornerRadius = 6
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inputContainer)
        
        inputField = NSTextField()
        inputField.placeholderString = "Send message to agent..."
        inputField.isBezeled = false
        inputField.drawsBackground = false
        inputField.textColor = Catppuccin.text
        inputField.font = NSFont.systemFont(ofSize: 13)
        inputField.focusRingType = .none
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.delegate = self
        inputContainer.addSubview(inputField)
        
        sendButton = NSButton(title: "↵", target: self, action: #selector(sendMessage))
        sendButton.bezelStyle = .inline
        sendButton.isBordered = false
        sendButton.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        sendButton.contentTintColor = Catppuccin.teal
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -8),
            
            inputContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            inputContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            inputContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            inputContainer.heightAnchor.constraint(equalToConstant: 36),
            
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32)
        ])
        
        // Initial message
        appendSystemMessage("Waiting for agent activity...")
    }
    
    func setProjectPath(_ path: String) {
        self.projectPath = path
        textView.string = ""
        appendSystemMessage("Connected to project: \(path)")
    }
    
    func appendMessage(_ message: OpenClawService.AgentMessage) {
        let timestamp = formatTime(message.timestamp)
        var color = Catppuccin.text
        var prefix = ""
        
        switch message.type {
        case .text:
            color = Catppuccin.text
            prefix = "💬"
        case .tool:
            color = Catppuccin.teal
            prefix = "🔧"
        case .thinking:
            color = Catppuccin.overlay1
            prefix = "🤔"
        case .error:
            color = Catppuccin.red
            prefix = "❌"
        case .system:
            color = Catppuccin.subtext0
            prefix = "ℹ️"
        }
        
        let line = NSMutableAttributedString()
        
        line.append(NSAttributedString(string: "[\(timestamp)] ", attributes: [
            .foregroundColor: Catppuccin.overlay0,
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        ]))
        
        line.append(NSAttributedString(string: "\(prefix) ", attributes: [
            .font: NSFont.systemFont(ofSize: 12)
        ]))
        
        line.append(NSAttributedString(string: message.content + "\n", attributes: [
            .foregroundColor: color,
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        ]))
        
        textView.textStorage?.append(line)
        scrollToBottom()
    }
    
    private func appendSystemMessage(_ text: String) {
        let timestamp = formatTime(Date())
        let line = NSMutableAttributedString()
        
        line.append(NSAttributedString(string: "[\(timestamp)] ℹ️ ", attributes: [
            .foregroundColor: Catppuccin.overlay0,
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        ]))
        
        line.append(NSAttributedString(string: text + "\n", attributes: [
            .foregroundColor: Catppuccin.subtext0,
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        ]))
        
        textView.textStorage?.append(line)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func scrollToBottom() {
        textView.scrollToEndOfDocument(nil)
    }
    
    @objc private func sendMessage() {
        let message = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        appendSystemMessage("You: \(message)")
        
        openClawService.sendMessage(message, to: "main") { success in
            if !success {
                self.appendSystemMessage("Failed to send message")
            }
        }
        
        inputField.stringValue = ""
    }
}

// MARK: - NSTextFieldDelegate

extension AgentActivityView: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            sendMessage()
            return true
        }
        return false
    }
}
