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
    // TODO: Add when services implemented
    // private let openClawService = OpenClawService.shared
    // private let vercelService = VercelService.shared
    
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
        // TODO: Add when OpenClaw service implemented
        // setupOpenClawConnection()
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
            if let headerCell = tableColumn.headerCell as? NSTableHeaderCell {
                headerCell.textColor = NSColor.white.withAlphaComponent(0.7)
            }
            
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
            self?.projects = projects
            self?.tableView.reloadData()
            self?.headerView.updateStats(projectCount: projects.count, buildStats: (ready: 0, building: 0, error: 0))
        }
    }
    
    // MARK: - Actions
    @objc private func tableViewDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < projects.count else { return }
        
        let project = projects[row]
        // Open in Finder for now
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
    }
    
    @objc func refreshProjects() {
        loadProjects()
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
            return createTextCell(text: project.name, color: .white, bold: true)
        case .agent:
            return createTextCell(text: project.agent ?? "-", color: .systemTeal)
        case .branches:
            return createTextCell(text: "\(project.gitState.branchCount)", color: .white)
        case .activeBranch:
            return createTextCell(text: project.gitState.activeBranch, color: .systemPurple)
        case .issues:
            return createTextCell(text: project.issuesDisplay, color: .systemOrange)
        case .stacks:
            return createTextCell(text: project.stacksDisplay, color: .systemBlue)
        case .untracked:
            let color: NSColor = project.gitState.untracked > 0 ? .systemRed : .secondaryLabelColor
            return createTextCell(text: project.untrackedDisplay, color: color)
        case .staged:
            let color: NSColor = project.gitState.staged > 0 ? .systemGreen : .secondaryLabelColor
            return createTextCell(text: project.stagedDisplay, color: color)
        case .age:
            return createTextCell(text: project.gitState.ageString, color: .secondaryLabelColor)
        case .lastMain:
            return createTextCell(text: project.gitState.lastMainString, color: .secondaryLabelColor)
        case .lastBranch:
            return createTextCell(text: project.gitState.lastBranchString, color: .secondaryLabelColor)
        case .comments:
            return createTextCell(text: project.commentsDisplay, color: .systemYellow)
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
        case .ready: cell.textColor = .systemGreen
        case .building: cell.textColor = .systemYellow
        case .queued: cell.textColor = .systemBlue
        case .error: cell.textColor = .systemRed
        case .none: cell.textColor = .secondaryLabelColor
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
            NSColor.white.withAlphaComponent(0.15).setFill()
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
        // Dark gradient background (similar to Discord/Slack dark themes)
        let gradient = NSGradient(colors: [
            NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0),
            NSColor(red: 0.12, green: 0.10, blue: 0.16, alpha: 1.0),
            NSColor(red: 0.10, green: 0.08, blue: 0.14, alpha: 1.0)
        ])
        
        gradient?.draw(in: bounds, angle: 135)
    }
}
