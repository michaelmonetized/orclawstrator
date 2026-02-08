import Cocoa

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
    private var statusPills: NSStackView!
    
    var onBack: (() -> Void)?
    
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
            
            statusPills.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            statusPills.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with project: Project) {
        titleLabel.stringValue = project.name
        pathLabel.stringValue = project.path
        languageIcon.stringValue = project.language.icon
        
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
}

// MARK: - Markdown Panel View

class MarkdownPanelView: NSView {
    
    private var tabBar: NSSegmentedControl!
    private var scrollView: NSScrollView!
    private var textView: NSTextView!
    private var saveButton: NSButton!
    private var statusLabel: NSTextField!
    private var currentProject: Project?
    private var currentFilePath: String?
    private var isEditing: Bool = false
    
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
        layer?.backgroundColor = Catppuccin.mantle.withAlphaComponent(0.7).cgColor
        layer?.cornerRadius = 8
        
        // Tab bar
        tabBar = NSSegmentedControl(labels: ["README", "PLAN", "ROADMAP", "CHANGELOG"], trackingMode: .selectOne, target: self, action: #selector(tabChanged))
        tabBar.selectedSegment = 0
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabBar)
        
        // Save button
        saveButton = NSButton(title: "Save", target: self, action: #selector(saveFile))
        saveButton.bezelStyle = .rounded
        saveButton.contentTintColor = Catppuccin.green
        saveButton.isHidden = true
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(saveButton)
        
        // Status label
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = NSFont.systemFont(ofSize: 10)
        statusLabel.textColor = Catppuccin.subtext0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        // Scroll view with text view for markdown
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // Editable text view
        textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = Catppuccin.base.withAlphaComponent(0.5)
        textView.textColor = Catppuccin.text
        textView.insertionPointColor = Catppuccin.text
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.autoresizingMask = [.width, .height]
        textView.delegate = self
        
        scrollView.documentView = textView
        
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            tabBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            
            saveButton.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            statusLabel.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -8),
            
            scrollView.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func loadProject(_ project: Project) {
        currentProject = project
        loadCurrentTab()
    }
    
    @objc private func tabChanged() {
        if isEditing {
            saveFile()
        }
        loadCurrentTab()
    }
    
    private func loadCurrentTab() {
        guard let project = currentProject else {
            textView.string = "No project selected"
            return
        }
        
        let filename = tabFiles[tabBar.selectedSegment]
        
        // Properly expand the path
        let projectPath = (project.path as NSString).expandingTildeInPath
        let filePath = (projectPath as NSString).appendingPathComponent(filename)
        
        currentFilePath = filePath
        isEditing = false
        saveButton.isHidden = true
        
        print("[Markdown] Loading: \(filePath)")
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            do {
                let content = try String(contentsOfFile: filePath, encoding: .utf8)
                print("[Markdown] Loaded \(content.count) characters from \(filename)")
                displayMarkdown(content)
                statusLabel.stringValue = "Loaded ✓"
                statusLabel.textColor = Catppuccin.green
            } catch {
                print("[Markdown] Error reading \(filename): \(error)")
                textView.string = "Error reading \(filename):\n\(error.localizedDescription)"
                textView.textColor = Catppuccin.red
                statusLabel.stringValue = "Error"
                statusLabel.textColor = Catppuccin.red
            }
        } else {
            print("[Markdown] File not found: \(filePath)")
            // File doesn't exist - show template
            let template = createTemplate(for: filename, projectName: project.name)
            textView.string = template
            textView.textColor = Catppuccin.subtext0
            statusLabel.stringValue = "New file"
            statusLabel.textColor = Catppuccin.yellow
        }
        
        // Clear status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.statusLabel.stringValue = ""
        }
    }
    
    private func createTemplate(for filename: String, projectName: String) -> String {
        let title = filename.replacingOccurrences(of: ".md", with: "")
        switch filename {
        case "README.md":
            return """
            # \(projectName)
            
            ## Description
            
            TODO: Describe what this project does.
            
            ## Installation
            
            TODO: Add installation instructions.
            
            ## Usage
            
            TODO: Add usage examples.
            
            ## License
            
            MIT
            """
        case "PLAN.md":
            return """
            # \(projectName) - Development Plan
            
            ## Goals
            
            - [ ] Goal 1
            - [ ] Goal 2
            
            ## Current Sprint
            
            ### In Progress
            
            - [ ] Task 1
            
            ### Done
            
            - [x] Initial setup
            """
        case "ROADMAP.md":
            return """
            # \(projectName) - Roadmap
            
            ## v1.0 (Current)
            
            - [ ] Core features
            - [ ] Basic UI
            
            ## v1.1 (Next)
            
            - [ ] Additional features
            - [ ] Improvements
            
            ## Future
            
            - [ ] Long-term goals
            """
        case "CHANGELOG.md":
            return """
            # Changelog
            
            All notable changes to \(projectName) will be documented in this file.
            
            ## [Unreleased]
            
            ### Added
            - Initial project setup
            
            ### Changed
            
            ### Fixed
            """
        default:
            return "# \(title)\n\nStart writing here..."
        }
    }
    
    @objc private func saveFile() {
        guard let filePath = currentFilePath else { return }
        
        let content = textView.string
        do {
            // Create directory if needed
            let directory = (filePath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            isEditing = false
            saveButton.isHidden = true
            statusLabel.stringValue = "Saved ✓"
            statusLabel.textColor = Catppuccin.green
            
            print("[Markdown] Saved to: \(filePath)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.statusLabel.stringValue = ""
            }
        } catch {
            statusLabel.stringValue = "Save failed"
            statusLabel.textColor = Catppuccin.red
            print("[Markdown] Save error: \(error)")
        }
    }
    
    private func displayMarkdown(_ markdown: String) {
        let attributed = renderMarkdown(markdown)
        textView.textStorage?.setAttributedString(attributed)
    }
    
    private func renderMarkdown(_ markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        
        let normalFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let h1Font = NSFont.systemFont(ofSize: 24, weight: .bold)
        let h2Font = NSFont.systemFont(ofSize: 20, weight: .bold)
        let h3Font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        let codeFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        var inCodeBlock = false
        
        for line in lines {
            let lineStr = String(line)
            var attrs: [NSAttributedString.Key: Any] = [
                .font: normalFont,
                .foregroundColor: Catppuccin.text
            ]
            var text = lineStr
            
            // Code blocks
            if lineStr.hasPrefix("```") {
                inCodeBlock = !inCodeBlock
                text = lineStr
                attrs[.foregroundColor] = Catppuccin.overlay2
            } else if inCodeBlock {
                attrs[.font] = codeFont
                attrs[.foregroundColor] = Catppuccin.green
                attrs[.backgroundColor] = Catppuccin.surface0
            }
            // Headers
            else if lineStr.hasPrefix("### ") {
                text = String(lineStr.dropFirst(4))
                attrs[.font] = h3Font
                attrs[.foregroundColor] = Catppuccin.mauve
            } else if lineStr.hasPrefix("## ") {
                text = String(lineStr.dropFirst(3))
                attrs[.font] = h2Font
                attrs[.foregroundColor] = Catppuccin.blue
            } else if lineStr.hasPrefix("# ") {
                text = String(lineStr.dropFirst(2))
                attrs[.font] = h1Font
                attrs[.foregroundColor] = Catppuccin.lavender
            }
            // Lists
            else if lineStr.hasPrefix("- ") || lineStr.hasPrefix("* ") {
                text = "  • " + String(lineStr.dropFirst(2))
            } else if lineStr.hasPrefix("  - ") || lineStr.hasPrefix("  * ") {
                text = "    ◦ " + String(lineStr.dropFirst(4))
            }
            // Checkboxes
            else if lineStr.contains("- [x]") {
                text = lineStr.replacingOccurrences(of: "- [x]", with: "  ✅")
                attrs[.foregroundColor] = Catppuccin.green
            } else if lineStr.contains("- [ ]") {
                text = lineStr.replacingOccurrences(of: "- [ ]", with: "  ☐")
                attrs[.foregroundColor] = Catppuccin.subtext0
            }
            
            result.append(NSAttributedString(string: text + "\n", attributes: attrs))
        }
        
        return result
    }
}

// MARK: - MarkdownPanelView NSTextViewDelegate

extension MarkdownPanelView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        if !isEditing {
            isEditing = true
            saveButton.isHidden = false
            statusLabel.stringValue = "Modified"
            statusLabel.textColor = Catppuccin.yellow
        }
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
