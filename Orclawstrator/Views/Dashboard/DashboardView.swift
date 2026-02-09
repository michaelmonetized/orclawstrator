import Cocoa

/// Dashboard view with "Dashboard" heading and project list
/// Matches mockup design with agent info, branch, stacks, git status, action icons
class DashboardView: NSView {
    
    // MARK: - UI Components
    
    private var headerLabel: NSTextField!
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    
    // MARK: - External References
    
    var topStatusBar: TopStatusBar?
    var onProjectSelected: ((Project) -> Void)?
    
    // MARK: - Data

    private var projects: [Project] = []
    private let projectScanner = ProjectScanner.shared
    private let openClawService = OpenClawService.shared
    private let database = DatabaseManager.shared
    private var agentStatsTimer: Timer?
    private var isLoadingFromScan = false
    
    // MARK: - Column Identifiers
    
    private enum Column: String, CaseIterable {
        case warning = "warning"
        case name = "name"
        case agent = "agent"
        case branch = "branch"
        case stacks = "stacks"
        case gitStatus = "gitStatus"
        case actions = "actions"
        
        var title: String {
            switch self {
            case .warning: return ""
            case .name: return "Project"
            case .agent: return "Agent"
            case .branch: return "Branch"
            case .stacks: return "Stacks"
            case .gitStatus: return "Changes"
            case .actions: return ""
            }
        }
        
        var width: CGFloat {
            switch self {
            case .warning: return 28
            case .name: return 180
            case .agent: return 200
            case .branch: return 200
            case .stacks: return 100
            case .gitStatus: return 160
            case .actions: return 160
            }
        }
    }
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadProjects()
        startAgentStatsPolling()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadProjects()
        startAgentStatsPolling()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Dashboard heading
        headerLabel = NSTextField(labelWithString: "Dashboard")
        headerLabel.font = NSFont.systemFont(ofSize: 28, weight: .bold)
        headerLabel.textColor = Catppuccin.text
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)
        
        // Scroll view for table
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        addSubview(scrollView)
        
        // Table view
        tableView = NSTableView()
        tableView.style = .plain
        tableView.backgroundColor = .clear
        tableView.rowHeight = 44
        tableView.intercellSpacing = NSSize(width: 8, height: 6)
        tableView.gridColor = .clear
        tableView.headerView = nil  // No header in mockup
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(tableViewDoubleClick)
        tableView.target = self
        
        // Add columns
        for column in Column.allCases {
            let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column.rawValue))
            tableColumn.title = column.title
            tableColumn.width = column.width
            tableColumn.minWidth = 50
            tableColumn.maxWidth = column.width * 2
            tableView.addTableColumn(tableColumn)
        }
        
        scrollView.documentView = tableView
        
        // Layout
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Data Loading

    private func loadProjects() {
        // Step 1: Load cached projects immediately for instant display
        let cachedProjects = database.getCachedProjects()
        if !cachedProjects.isEmpty {
            self.projects = cachedProjects
            self.tableView.reloadData()
            let buildStats = self.calculateBuildStats()
            self.topStatusBar?.updateStats(projectCount: cachedProjects.count, buildStats: buildStats)
        }

        // Step 2: Scan in background and update incrementally
        isLoadingFromScan = true
        projectScanner.onProjectScanned = { [weak self] project, current, total in
            guard let self = self else { return }
            // Save to database for next launch
            self.database.saveProject(project)
            // Update or add project in list
            self.updateProject(project)
        }

        projectScanner.scanProjects(in: "~/Projects") { [weak self] projects in
            guard let self = self else { return }
            self.isLoadingFromScan = false
            self.projects = projects
            self.tableView.reloadData()
            let buildStats = self.calculateBuildStats()
            self.topStatusBar?.updateStats(projectCount: projects.count, buildStats: buildStats)
        }
    }

    /// Update a single project in the list (for incremental updates)
    private func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.path == project.path }) {
            // Update existing project
            projects[index] = project
            let indexSet = IndexSet(integer: index)
            tableView.reloadData(forRowIndexes: indexSet, columnIndexes: IndexSet(integersIn: 0..<tableView.numberOfColumns))
        } else {
            // Add new project and sort
            projects.append(project)
            projects.sort { $0.name.lowercased() < $1.name.lowercased() }
            tableView.reloadData()
        }

        // Update stats
        let buildStats = calculateBuildStats()
        topStatusBar?.updateStats(projectCount: projects.count, buildStats: buildStats)
    }

    func refreshProjects() {
        loadProjects()
    }
    
    // MARK: - Build Stats
    
    private func calculateBuildStats() -> (ready: Int, building: Int, error: Int) {
        var ready = 0, building = 0, error = 0
        
        for project in projects {
            switch project.buildStatus {
            case .ready: ready += 1
            case .building, .queued: building += 1
            case .error: error += 1
            case .none: break
            }
        }
        
        return (ready, building, error)
    }
    
    // MARK: - Agent Stats Polling

    private func startAgentStatsPolling() {
        agentStatsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateAgentStats()
        }
        updateAgentStats()
    }

    deinit {
        agentStatsTimer?.invalidate()
        agentStatsTimer = nil
    }
    
    private func updateAgentStats() {
        openClawService.getUsageStats { [weak self] stats in
            self?.topStatusBar?.updateAgentStats(
                agents: stats.activeSessions,
                subs: stats.subagents,
                idle: stats.idleSessions
            )
            self?.topStatusBar?.updateTokenUsage(used: stats.totalTokens, total: stats.tokenLimit)
        }
    }
    
    // MARK: - Actions
    
    @objc private func tableViewDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < projects.count else { return }
        let project = projects[row]
        onProjectSelected?(project)
    }
}

// MARK: - NSTableViewDataSource

extension DashboardView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return projects.count
    }
}

// MARK: - NSTableViewDelegate

extension DashboardView: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn,
              let columnType = Column(rawValue: column.identifier.rawValue),
              row < projects.count else { return nil }
        
        let project = projects[row]
        
        switch columnType {
        case .warning:
            return createWarningCell(for: project)
        case .name:
            return createNameCell(for: project)
        case .agent:
            return createAgentCell(for: project)
        case .branch:
            return createBranchCell(for: project)
        case .stacks:
            return createStacksCell(for: project)
        case .gitStatus:
            return createGitStatusCell(for: project)
        case .actions:
            return createActionsCell(for: project, row: row)
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return DashboardRowView()
    }
    
    // MARK: - Cell Factories
    
    private func createWarningCell(for project: Project) -> NSView {
        let cell = NSView()
        
        let icon = NSTextField(labelWithString: project.hasWarning ? "⚠️" : "")
        icon.alignment = .center
        icon.font = NSFont.systemFont(ofSize: 14)
        icon.toolTip = project.warningMessage
        icon.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        
        return cell
    }
    
    private func createNameCell(for project: Project) -> NSView {
        let cell = NSStackView()
        cell.orientation = .horizontal
        cell.spacing = 8
        cell.alignment = .centerY
        
        // Language icon
        let langIcon = NSTextField(labelWithString: project.language.icon)
        langIcon.font = NSFont.systemFont(ofSize: 14)
        cell.addArrangedSubview(langIcon)
        
        // Project name
        let nameLabel = NSTextField(labelWithString: project.name)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = Catppuccin.text
        nameLabel.lineBreakMode = .byTruncatingTail
        cell.addArrangedSubview(nameLabel)
        
        return cell
    }
    
    private func createAgentCell(for project: Project) -> NSView {
        let cell = NSStackView()
        cell.orientation = .horizontal
        cell.spacing = 6
        cell.alignment = .centerY
        
        // Agent avatar (colored dot or icon)
        let avatarView = NSView()
        avatarView.wantsLayer = true
        avatarView.layer?.backgroundColor = Catppuccin.mauve.cgColor
        avatarView.layer?.cornerRadius = 8
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        cell.addArrangedSubview(avatarView)
        
        // Agent name (e.g., "Rusty P. Shackelford")
        let agentName = project.agent ?? "No agent"
        let nameLabel = NSTextField(labelWithString: agentName)
        nameLabel.font = NSFont.systemFont(ofSize: 11)
        nameLabel.textColor = Catppuccin.teal
        nameLabel.lineBreakMode = .byTruncatingTail
        cell.addArrangedSubview(nameLabel)
        
        // Agent count (e.g., "01 main 03 subs")
        let countLabel = NSTextField(labelWithString: "01 main 00 subs")
        countLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        countLabel.textColor = Catppuccin.subtext0
        cell.addArrangedSubview(countLabel)
        
        return cell
    }
    
    private func createBranchCell(for project: Project) -> NSView {
        let cell = NSStackView()
        cell.orientation = .horizontal
        cell.spacing = 6
        cell.alignment = .centerY
        
        // Branch icon
        let branchIcon = NSTextField(labelWithString: "⑂")
        branchIcon.font = NSFont.systemFont(ofSize: 12)
        branchIcon.textColor = Catppuccin.green
        cell.addArrangedSubview(branchIcon)
        
        // Branch count
        let branchCount = NSTextField(labelWithString: String(format: "%02d", project.gitState.branchCount))
        branchCount.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        branchCount.textColor = Catppuccin.green
        cell.addArrangedSubview(branchCount)
        
        // Active branch name
        let activeBranch = NSTextField(labelWithString: project.gitState.activeBranch)
        activeBranch.font = NSFont.systemFont(ofSize: 11)
        activeBranch.textColor = Catppuccin.subtext1
        activeBranch.lineBreakMode = .byTruncatingTail
        cell.addArrangedSubview(activeBranch)
        
        return cell
    }
    
    private func createStacksCell(for project: Project) -> NSView {
        let cell = StacksCellView(project: project)
        return cell
    }

    private func createGitStatusCell(for project: Project) -> NSView {
        let cell = NSStackView()
        cell.orientation = .horizontal
        cell.spacing = 8
        cell.alignment = .centerY
        
        // Untracked (red)
        if project.gitState.untracked > 0 {
            let untrackedIcon = NSTextField(labelWithString: "◆")
            untrackedIcon.textColor = Catppuccin.red
            untrackedIcon.font = NSFont.systemFont(ofSize: 10)
            cell.addArrangedSubview(untrackedIcon)
            
            let untrackedCount = NSTextField(labelWithString: String(format: "%02d", project.gitState.untracked))
            untrackedCount.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
            untrackedCount.textColor = Catppuccin.red
            cell.addArrangedSubview(untrackedCount)
            
            let untrackedLabel = NSTextField(labelWithString: "untracked")
            untrackedLabel.font = NSFont.systemFont(ofSize: 10)
            untrackedLabel.textColor = Catppuccin.red.withAlphaComponent(0.7)
            cell.addArrangedSubview(untrackedLabel)
        }
        
        // Staged (green)
        if project.gitState.staged > 0 {
            let stagedCount = NSTextField(labelWithString: String(format: "%02d", project.gitState.staged))
            stagedCount.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
            stagedCount.textColor = Catppuccin.green
            cell.addArrangedSubview(stagedCount)
            
            let stagedLabel = NSTextField(labelWithString: "staged")
            stagedLabel.font = NSFont.systemFont(ofSize: 10)
            stagedLabel.textColor = Catppuccin.green.withAlphaComponent(0.7)
            cell.addArrangedSubview(stagedLabel)
        }
        
        // If no changes
        if project.gitState.untracked == 0 && project.gitState.staged == 0 {
            let noChanges = NSTextField(labelWithString: "Clean")
            noChanges.font = NSFont.systemFont(ofSize: 10)
            noChanges.textColor = Catppuccin.overlay0
            cell.addArrangedSubview(noChanges)
        }
        
        return cell
    }
    
    private func createActionsCell(for project: Project, row: Int) -> NSView {
        let container = NSView()

        let cell = NSStackView()
        cell.orientation = .horizontal
        cell.spacing = 4
        cell.alignment = .centerY
        cell.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(cell)

        // Action buttons - minimal set
        let actions: [(icon: String, tooltip: String)] = [
            ("📂", "Open folder"),
            ("🔗", "Open in terminal"),
            ("⋯", "More options")
        ]

        for (icon, tooltip) in actions {
            let button = NSButton(title: icon, target: self, action: #selector(actionButtonClicked(_:)))
            button.bezelStyle = .inline
            button.isBordered = false
            button.font = NSFont.systemFont(ofSize: 12)
            button.toolTip = tooltip
            button.tag = row
            button.contentTintColor = Catppuccin.overlay1
            cell.addArrangedSubview(button)
        }

        // Pin to right side
        NSLayoutConstraint.activate([
            cell.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            cell.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }
    
    @objc private func actionButtonClicked(_ sender: NSButton) {
        let row = sender.tag
        guard row >= 0, row < projects.count else { return }
        let project = projects[row]

        switch sender.title {
        case "📂":
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
        case "🔗":
            // Open in terminal
            let script = "tell application \"Terminal\" to do script \"cd '\(project.path)'\""
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(nil)
            }
        default:
            break
        }
    }
}

// MARK: - Stacks Cell View (Clickable)

class StacksCellView: NSView {
    private let project: Project
    private var popover: PRStackPopover?

    init(project: Project) {
        self.project = project
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        // Stack icon
        let stackIcon = NSTextField(labelWithString: "n̄")
        stackIcon.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        stackIcon.textColor = Catppuccin.blue
        stack.addArrangedSubview(stackIcon)

        // Stack count
        let stackCount = NSTextField(labelWithString: String(format: "%02d", project.stackCount))
        stackCount.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        stackCount.textColor = Catppuccin.blue
        stack.addArrangedSubview(stackCount)

        // Label
        let label = NSTextField(labelWithString: "stacked")
        label.font = NSFont.systemFont(ofSize: 10)
        label.textColor = Catppuccin.subtext0
        stack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Make clickable if has stacks
        if project.stackCount > 0 {
            let click = NSClickGestureRecognizer(target: self, action: #selector(showStackPopover))
            addGestureRecognizer(click)
            toolTip = "Click to view PR stack"
        }
    }

    @objc private func showStackPopover() {
        popover = PRStackPopover(project: project)
        popover?.show(relativeTo: bounds, of: self, preferredEdge: .maxY)
    }
}

// MARK: - Dashboard Row View

class DashboardRowView: NSTableRowView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Semi-transparent row background
        Catppuccin.surface0.withAlphaComponent(0.3).setFill()
        let rowRect = bounds.insetBy(dx: 4, dy: 2)
        let path = NSBezierPath(roundedRect: rowRect, xRadius: 6, yRadius: 6)
        path.fill()
        
        // Highlight on selection
        if isSelected {
            Catppuccin.surface1.withAlphaComponent(0.5).setFill()
            path.fill()
        }
    }
    
    override var isEmphasized: Bool {
        get { true }
        set { }
    }
}
