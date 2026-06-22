import Cocoa

/// Spotlight-like quick switcher for projects (Cmd+K)
class QuickSwitcherPanel: NSPanel {

    private var searchField: NSTextField!
    private var resultsTableView: NSTableView!
    private var resultsScrollView: NSScrollView!

    private var allProjects: [Project] = []
    private var filteredProjects: [Project] = []

    var onProjectSelected: ((Project) -> Void)?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .fullSizeContentView], backing: backingStoreType, defer: flag)

        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.backgroundColor = Catppuccin.base.withAlphaComponent(0.95)
        self.level = .floating
        self.hasShadow = true

        setupUI()
    }

    private func setupUI() {
        guard let contentView = self.contentView else { return }

        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = Catppuccin.base.withAlphaComponent(0.95).cgColor
        contentView.layer?.cornerRadius = 12

        // Search field
        searchField = NSTextField()
        searchField.placeholderString = "Search projects..."
        searchField.font = NSFont.systemFont(ofSize: 18)
        searchField.isBezeled = false
        searchField.drawsBackground = false
        searchField.textColor = Catppuccin.text
        searchField.focusRingType = .none
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchField)

        // Search icon
        let searchIcon = NSTextField(labelWithString: "🔍")
        searchIcon.font = NSFont.systemFont(ofSize: 18)
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchIcon)

        // Divider
        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = Catppuccin.surface1.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(divider)

        // Results scroll view
        resultsScrollView = NSScrollView()
        resultsScrollView.hasVerticalScroller = true
        resultsScrollView.autohidesScrollers = true
        resultsScrollView.borderType = .noBorder
        resultsScrollView.drawsBackground = false
        resultsScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resultsScrollView)

        // Results table
        resultsTableView = NSTableView()
        resultsTableView.headerView = nil
        resultsTableView.backgroundColor = .clear
        resultsTableView.rowHeight = 44
        resultsTableView.intercellSpacing = NSSize(width: 0, height: 2)
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.doubleAction = #selector(selectProject)
        resultsTableView.target = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("project"))
        column.width = 480
        resultsTableView.addTableColumn(column)

        resultsScrollView.documentView = resultsTableView

        NSLayoutConstraint.activate([
            searchIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),

            searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            searchField.centerYAnchor.constraint(equalTo: searchIcon.centerYAnchor),

            divider.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            divider.heightAnchor.constraint(equalToConstant: 1),

            resultsScrollView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8),
            resultsScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            resultsScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            resultsScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func show(with projects: [Project]) {
        allProjects = projects
        filteredProjects = projects
        searchField.stringValue = ""
        resultsTableView.reloadData()

        // Select first row
        if !filteredProjects.isEmpty {
            resultsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY + frame.height / 2
            setFrameTopLeftPoint(NSPoint(x: x, y: y))
        }

        makeKeyAndOrderFront(nil)
        searchField.becomeFirstResponder()
    }

    func hide() {
        orderOut(nil)
    }

    private func filterProjects() {
        let query = searchField.stringValue.lowercased()
        if query.isEmpty {
            filteredProjects = allProjects
        } else {
            filteredProjects = allProjects.filter { project in
                project.name.lowercased().contains(query) ||
                project.path.lowercased().contains(query) ||
                project.language.rawValue.lowercased().contains(query)
            }
        }
        resultsTableView.reloadData()

        // Select first row
        if !filteredProjects.isEmpty {
            resultsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    @objc private func selectProject() {
        let row = resultsTableView.selectedRow
        guard row >= 0, row < filteredProjects.count else { return }

        let project = filteredProjects[row]
        hide()
        onProjectSelected?(project)
    }

    // Handle keyboard navigation
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            hide()
        case 36, 76: // Return, Enter
            selectProject()
        case 125: // Down arrow
            let newRow = min(resultsTableView.selectedRow + 1, filteredProjects.count - 1)
            resultsTableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
            resultsTableView.scrollRowToVisible(newRow)
        case 126: // Up arrow
            let newRow = max(resultsTableView.selectedRow - 1, 0)
            resultsTableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
            resultsTableView.scrollRowToVisible(newRow)
        default:
            super.keyDown(with: event)
        }
    }
}

// MARK: - NSTextFieldDelegate

extension QuickSwitcherPanel: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        filterProjects()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            selectProject()
            return true
        } else if commandSelector == #selector(cancelOperation(_:)) {
            hide()
            return true
        } else if commandSelector == #selector(moveDown(_:)) {
            let newRow = min(resultsTableView.selectedRow + 1, filteredProjects.count - 1)
            resultsTableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
            resultsTableView.scrollRowToVisible(newRow)
            return true
        } else if commandSelector == #selector(moveUp(_:)) {
            let newRow = max(resultsTableView.selectedRow - 1, 0)
            resultsTableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
            resultsTableView.scrollRowToVisible(newRow)
            return true
        }
        return false
    }
}

// MARK: - NSTableViewDataSource

extension QuickSwitcherPanel: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredProjects.count
    }
}

// MARK: - NSTableViewDelegate

extension QuickSwitcherPanel: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredProjects.count else { return nil }
        let project = filteredProjects[row]

        let cell = NSView()

        // Language icon
        let iconLabel = NSTextField(labelWithString: project.language.icon)
        iconLabel.font = NSFont.systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(iconLabel)

        // Project name
        let nameLabel = NSTextField(labelWithString: project.name)
        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = Catppuccin.text
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(nameLabel)

        // Path
        let pathLabel = NSTextField(labelWithString: project.path)
        pathLabel.font = NSFont.systemFont(ofSize: 11)
        pathLabel.textColor = Catppuccin.subtext0
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(pathLabel)

        // Git status
        var statusText = ""
        if project.gitState.untracked > 0 {
            statusText += "\(project.gitState.untracked) untracked "
        }
        if project.gitState.staged > 0 {
            statusText += "\(project.gitState.staged) staged"
        }
        if statusText.isEmpty {
            statusText = "Clean"
        }

        let statusLabel = NSTextField(labelWithString: statusText)
        statusLabel.font = NSFont.systemFont(ofSize: 10)
        statusLabel.textColor = project.gitState.untracked > 0 ? Catppuccin.red : Catppuccin.green
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 6),

            pathLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            pathLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            statusLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12),
            statusLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])

        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return QuickSwitcherRowView()
    }
}

// MARK: - Row View

class QuickSwitcherRowView: NSTableRowView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isSelected {
            Catppuccin.surface1.withAlphaComponent(0.7).setFill()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 1), xRadius: 6, yRadius: 6)
            path.fill()
        }
    }

    override var isEmphasized: Bool {
        get { true }
        set { }
    }
}
