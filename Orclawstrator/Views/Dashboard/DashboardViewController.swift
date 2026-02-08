import Cocoa

class DashboardViewController: NSViewController {
    
    // MARK: - UI Components
    private var headerView: TopBarView!
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var gradientView: GradientBackgroundView!
    
    // MARK: - Data
    private var projects: [Project] = []
    private let projectScanner = ProjectScanner.shared
    private let openClawService = OpenClawService.shared
    private let vercelService = VercelService.shared
    
    // MARK: - Callbacks
    var onProjectSelected: ((Project) -> Void)?
    
    // MARK: - Column Identifiers
    private enum Column: String, CaseIterable {
        case warning = "warning"
        case language = "language"
        case name = "name"
        case agent = "agent"
        case branches = "branches"
        case activeBranch = "activeBranch"
        case issues = "issues"
        case stacks = "stacks"
        case untracked = "untracked"
        case staged = "staged"
        case age = "age"
        case lastMain = "lastMain"
        case lastBranch = "lastBranch"
        case comments = "comments"
        case build = "build"
        case actions = "actions"
        
        var title: String {
            switch self {
            case .warning: return ""
            case .language: return ""
            case .name: return "Project"
            case .agent: return "Agent"
            case .branches: return "Branches"
            case .activeBranch: return "Active"
            case .issues: return "Issues"
            case .stacks: return "Stacks"
            case .untracked: return "Untrk"
            case .staged: return "Stgd"
            case .age: return "Age"
            case .lastMain: return "Main"
            case .lastBranch: return "Branch"
            case .comments: return "Comments"
            case .build: return "Build"
            case .actions: return ""
            }
        }
        
        var width: CGFloat {
            switch self {
            case .warning: return 24
            case .language: return 28
            case .name: return 180
            case .agent: return 140
            case .branches: return 70
            case .activeBranch: return 120
            case .issues: return 50
            case .stacks: return 50
            case .untracked: return 45
            case .staged: return 45
            case .age: return 70
            case .lastMain: return 60
            case .lastBranch: return 60
            case .comments: return 70
            case .build: return 70
            case .actions: return 150
            }
        }
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupHeaderView()
        setupTableView()
        loadProjects()
        setupOpenClawConnection()
        startAgentStatsPolling()
    }
    
    // MARK: - Setup
    private func setupGradientBackground() {
        gradientView = GradientBackgroundView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)
        
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupHeaderView() {
        headerView = TopBarView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTableView() {
        // Create scroll view
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        // Create table view
        tableView = NSTableView()
        tableView.style = .plain
        tableView.backgroundColor = .clear
        tableView.rowHeight = 36
        tableView.intercellSpacing = NSSize(width: 8, height: 4)
        tableView.gridColor = NSColor.white.withAlphaComponent(0.1)
        tableView.gridStyleMask = .solidHorizontalGridLineMask
        tableView.headerView = createHeaderView()
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
            tableColumn.minWidth = column == .name ? 100 : 30
            tableColumn.maxWidth = column == .name ? 300 : column.width * 2
            
            // Header text color
            tableColumn.headerCell.textColor = Catppuccin.subtext0
            
            tableView.addTableColumn(tableColumn)
        }
        
        scrollView.documentView = tableView
    }
    
    private func createHeaderView() -> NSTableHeaderView {
        let headerView = NSTableHeaderView()
        return headerView
    }
    
    // MARK: - Data Loading
    private func loadProjects() {
        projectScanner.scanProjects(in: "~/Projects") { [weak self] projects in
            guard let self = self else { return }
            self.projects = projects
            self.tableView.reloadData()
            let buildStats = self.calculateBuildStats()
            self.headerView.updateStats(projectCount: projects.count, buildStats: buildStats)
        }
    }
    
    // MARK: - Actions
    @objc private func tableViewDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < projects.count else { return }
        
        let project = projects[row]
        
        // Call the callback to show project detail
        if let onProjectSelected = onProjectSelected {
            onProjectSelected(project)
        } else {
            // Fallback: open in Finder
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
        }
    }
    
    @objc func refreshProjects() {
        loadProjects()
    }
    
    // MARK: - OpenClaw Integration
    
    private func setupOpenClawConnection() {
        openClawService.onConnectionStateChanged = { [weak self] state in
            guard let self = self else { return }
            // Update status bar via notification or direct reference
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenClawConnectionChanged"),
                object: nil,
                userInfo: ["connected": self.openClawService.isConnected]
            )
        }
        
        openClawService.onAgentMessage = { message in
            // Handle incoming agent messages
            NotificationCenter.default.post(
                name: NSNotification.Name("AgentMessageReceived"),
                object: nil,
                userInfo: ["message": message]
            )
        }
        
        // Connect to gateway
        openClawService.connect()
    }
    
    private func startAgentStatsPolling() {
        // Poll for agent stats every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateAgentStats()
        }
        // Initial update
        updateAgentStats()
    }
    
    private func updateAgentStats() {
        openClawService.getUsageStats { [weak self] stats in
            self?.headerView.updateAgentStats(
                agents: stats.activeSessions,
                subs: stats.subagents,
                idle: stats.idleSessions
            )
            self?.headerView.updateTokenUsage(used: stats.totalTokens, total: stats.tokenLimit)
        }
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
}

// MARK: - NSTableViewDataSource

extension DashboardViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return projects.count
    }
}

// MARK: - NSTableViewDelegate

extension DashboardViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn,
              let columnType = Column(rawValue: column.identifier.rawValue),
              row < projects.count else { return nil }
        
        let project = projects[row]
        
        switch columnType {
        case .warning:
            return createWarningCell(for: project)
        case .language:
            return createLanguageCell(for: project)
        case .name:
            return createTextCell(text: project.name, color: Catppuccin.text, bold: true)
        case .agent:
            return createTextCell(text: project.agent ?? "-", color: Catppuccin.teal)
        case .branches:
            return createTextCell(text: "\(project.gitState.branchCount)", color: Catppuccin.text)
        case .activeBranch:
            return createTextCell(text: project.gitState.activeBranch, color: Catppuccin.mauve)
        case .issues:
            return createTextCell(text: project.issuesDisplay, color: Catppuccin.peach)
        case .stacks:
            return createTextCell(text: project.stacksDisplay, color: Catppuccin.blue)
        case .untracked:
            let color: NSColor = project.gitState.untracked > 0 ? Catppuccin.red : Catppuccin.overlay0
            return createTextCell(text: project.untrackedDisplay, color: color)
        case .staged:
            let color: NSColor = project.gitState.staged > 0 ? Catppuccin.green : Catppuccin.overlay0
            return createTextCell(text: project.stagedDisplay, color: color)
        case .age:
            return createTextCell(text: project.gitState.ageString, color: Catppuccin.subtext0)
        case .lastMain:
            return createTextCell(text: project.gitState.lastMainString, color: Catppuccin.subtext0)
        case .lastBranch:
            return createTextCell(text: project.gitState.lastBranchString, color: Catppuccin.subtext0)
        case .comments:
            return createTextCell(text: project.commentsDisplay, color: Catppuccin.yellow)
        case .build:
            return createBuildStatusCell(for: project)
        case .actions:
            return createActionsCell(for: project, row: row)
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = ProjectRowView()
        return rowView
    }
    
    // MARK: - Cell Factories
    
    private func createWarningCell(for project: Project) -> NSView {
        let cell = NSTextField(labelWithString: project.hasWarning ? "⚠️" : "")
        cell.alignment = .center
        cell.toolTip = project.warningMessage
        return cell
    }
    
    private func createLanguageCell(for project: Project) -> NSView {
        let cell = NSTextField(labelWithString: project.language.icon)
        cell.alignment = .center
        cell.toolTip = project.language.displayName
        return cell
    }
    
    private func createTextCell(text: String, color: NSColor, bold: Bool = false) -> NSView {
        let cell = NSTextField(labelWithString: text)
        cell.textColor = color
        cell.font = bold ? NSFont.systemFont(ofSize: 12, weight: .semibold) : NSFont.systemFont(ofSize: 12)
        cell.lineBreakMode = .byTruncatingTail
        return cell
    }
    
    private func createBuildStatusCell(for project: Project) -> NSView {
        let cell = NSTextField(labelWithString: project.buildStatus.rawValue)
        cell.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        
        switch project.buildStatus {
        case .ready: cell.textColor = Catppuccin.green
        case .building: cell.textColor = Catppuccin.yellow
        case .queued: cell.textColor = Catppuccin.blue
        case .error: cell.textColor = Catppuccin.red
        case .none: cell.textColor = Catppuccin.overlay0
        }
        
        return cell
    }
    
    private func createActionsCell(for project: Project, row: Int) -> NSView {
        let container = NSStackView()
        container.orientation = .horizontal
        container.spacing = 4
        container.distribution = .fillEqually
        
        let buttons = [
            ("🔗", "Open folder"),
            ("📖", "View README"),
            ("📝", "View PLAN"),
            ("📋", "View ROADMAP")
        ]
        
        for (icon, tooltip) in buttons {
            let button = NSButton(title: icon, target: self, action: #selector(actionButtonClicked(_:)))
            button.bezelStyle = .inline
            button.isBordered = false
            button.toolTip = tooltip
            button.tag = row
            container.addArrangedSubview(button)
        }
        
        return container
    }
    
    @objc private func actionButtonClicked(_ sender: NSButton) {
        let row = sender.tag
        guard row >= 0, row < projects.count else { return }
        
        let project = projects[row]
        
        switch sender.title {
        case "🔗":
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
        case "📖":
            openFile(named: "README.md", in: project)
        case "📝":
            openFile(named: "PLAN.md", in: project)
        case "📋":
            openFile(named: "ROADMAP.md", in: project)
        default:
            break
        }
    }
    
    private func openFile(named filename: String, in project: Project) {
        let filePath = (project.path as NSString).appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: filePath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
        }
    }
}

// MARK: - Custom Row View

class ProjectRowView: NSTableRowView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Custom background for selected rows
        if isSelected {
            Catppuccin.surface1.withAlphaComponent(0.6).setFill()
            let selectionRect = bounds.insetBy(dx: 4, dy: 2)
            let path = NSBezierPath(roundedRect: selectionRect, xRadius: 6, yRadius: 6)
            path.fill()
        }
    }
    
    override var isEmphasized: Bool {
        get { return true }
        set { }
    }
}

// MARK: - Gradient Background View

class GradientBackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        // Catppuccin-inspired gradient background
        let gradient = NSGradient(colors: [
            Catppuccin.crust,
            Catppuccin.base,
            Catppuccin.mantle
        ])
        
        gradient?.draw(in: bounds, angle: 135)
    }
}
