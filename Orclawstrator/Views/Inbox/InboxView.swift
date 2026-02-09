import Cocoa

/// Global Inbox view showing all agent messages across sessions
class InboxView: NSView {

    // MARK: - UI Components

    private var headerStack: NSStackView!
    private var headerLabel: NSTextField!
    private var filterPopup: NSPopUpButton!
    private var markAllReadButton: NSButton!
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var unreadOnlyCheckbox: NSButton!

    // MARK: - Data

    private var messages: [DatabaseManager.InboxMessage] = []
    private var sessions: [String] = []
    private var selectedSession: String?
    private var showUnreadOnly: Bool = false
    private let database = DatabaseManager.shared

    // MARK: - Callbacks

    var onMessageSelected: ((DatabaseManager.InboxMessage) -> Void)?
    var onBack: (() -> Void)?

    // MARK: - Column Identifiers

    private enum Column: String {
        case status = "status"
        case session = "session"
        case type = "type"
        case content = "content"
        case time = "time"
    }

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadData()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        // Header with back button
        let backButton = NSButton(title: "←", target: self, action: #selector(backClicked))
        backButton.bezelStyle = .inline
        backButton.isBordered = false
        backButton.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        backButton.contentTintColor = Catppuccin.text

        // Header label
        headerLabel = NSTextField(labelWithString: "Inbox")
        headerLabel.font = NSFont.systemFont(ofSize: 28, weight: .bold)
        headerLabel.textColor = Catppuccin.text

        // Filter dropdown
        filterPopup = NSPopUpButton()
        filterPopup.addItem(withTitle: "All Sessions")
        filterPopup.target = self
        filterPopup.action = #selector(filterChanged)

        // Unread only checkbox
        unreadOnlyCheckbox = NSButton(checkboxWithTitle: "Unread only", target: self, action: #selector(unreadFilterChanged))
        unreadOnlyCheckbox.contentTintColor = Catppuccin.text

        // Mark all read button
        markAllReadButton = NSButton(title: "Mark All Read", target: self, action: #selector(markAllRead))
        markAllReadButton.bezelStyle = .rounded
        markAllReadButton.contentTintColor = Catppuccin.teal

        // Header stack
        headerStack = NSStackView(views: [backButton, headerLabel, NSView(), filterPopup, unreadOnlyCheckbox, markAllReadButton])
        headerStack.orientation = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .centerY
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerStack)

        // Table scroll view
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
        tableView.rowHeight = 60
        tableView.intercellSpacing = NSSize(width: 8, height: 4)
        tableView.gridColor = .clear
        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(tableViewDoubleClick)
        tableView.target = self

        // Add columns
        let columns: [(Column, CGFloat)] = [
            (.status, 30),
            (.session, 120),
            (.type, 80),
            (.content, 400),
            (.time, 100)
        ]

        for (col, width) in columns {
            let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(col.rawValue))
            tableColumn.width = width
            tableColumn.minWidth = 50
            tableView.addTableColumn(tableColumn)
        }

        scrollView.documentView = tableView

        // Layout
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Data Loading

    private func loadData() {
        // Load sessions for filter
        sessions = database.getUniqueSessions()
        filterPopup.removeAllItems()
        filterPopup.addItem(withTitle: "All Sessions")
        for session in sessions {
            filterPopup.addItem(withTitle: session)
        }

        // Load messages
        messages = database.getAllMessages(sessionId: selectedSession, unreadOnly: showUnreadOnly)
        tableView.reloadData()

        // Update header with unread count
        let unreadCount = database.getUnreadMessageCount()
        if unreadCount > 0 {
            headerLabel.stringValue = "Inbox (\(unreadCount) unread)"
        } else {
            headerLabel.stringValue = "Inbox"
        }
    }

    func refresh() {
        loadData()
    }

    // MARK: - Actions

    @objc private func backClicked() {
        onBack?()
    }

    @objc private func filterChanged() {
        let index = filterPopup.indexOfSelectedItem
        if index == 0 {
            selectedSession = nil
        } else {
            selectedSession = sessions[index - 1]
        }
        loadData()
    }

    @objc private func unreadFilterChanged() {
        showUnreadOnly = unreadOnlyCheckbox.state == .on
        loadData()
    }

    @objc private func markAllRead() {
        database.markAllMessagesAsRead()
        loadData()
    }

    @objc private func tableViewDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < messages.count else { return }
        let message = messages[row]

        // Mark as read
        database.markMessageAsRead(id: message.id)
        loadData()

        onMessageSelected?(message)
    }
}

// MARK: - NSTableViewDataSource

extension InboxView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return messages.count
    }
}

// MARK: - NSTableViewDelegate

extension InboxView: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn,
              let columnType = Column(rawValue: column.identifier.rawValue),
              row < messages.count else { return nil }

        let message = messages[row]

        switch columnType {
        case .status:
            return createStatusCell(for: message)
        case .session:
            return createSessionCell(for: message)
        case .type:
            return createTypeCell(for: message)
        case .content:
            return createContentCell(for: message)
        case .time:
            return createTimeCell(for: message)
        }
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return InboxRowView()
    }

    // MARK: - Cell Factories

    private func createStatusCell(for message: DatabaseManager.InboxMessage) -> NSView {
        let cell = NSView()
        let dot = NSView()
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 5
        dot.layer?.backgroundColor = message.isRead ? Catppuccin.overlay0.cgColor : Catppuccin.blue.cgColor
        dot.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(dot)

        NSLayoutConstraint.activate([
            dot.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            dot.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10)
        ])

        return cell
    }

    private func createSessionCell(for message: DatabaseManager.InboxMessage) -> NSView {
        let label = NSTextField(labelWithString: message.sessionId)
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        label.textColor = Catppuccin.mauve
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    private func createTypeCell(for message: DatabaseManager.InboxMessage) -> NSView {
        let cell = NSView()
        let pill = NSView()
        pill.wantsLayer = true
        pill.layer?.cornerRadius = 8

        let color: NSColor
        let icon: String
        switch message.type {
        case "text": color = Catppuccin.text; icon = "💬"
        case "tool": color = Catppuccin.teal; icon = "🔧"
        case "thinking": color = Catppuccin.overlay1; icon = "🤔"
        case "error": color = Catppuccin.red; icon = "❌"
        case "system": color = Catppuccin.subtext0; icon = "ℹ️"
        default: color = Catppuccin.text; icon = "📨"
        }

        pill.layer?.backgroundColor = color.withAlphaComponent(0.2).cgColor

        let label = NSTextField(labelWithString: "\(icon) \(message.type)")
        label.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(label)
        pill.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(pill)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -6),
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -3),

            pill.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            pill.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])

        return cell
    }

    private func createContentCell(for message: DatabaseManager.InboxMessage) -> NSView {
        let cell = NSStackView()
        cell.orientation = .vertical
        cell.alignment = .leading
        cell.spacing = 2

        // Content preview (first 100 chars)
        let preview = String(message.content.prefix(100)).replacingOccurrences(of: "\n", with: " ")
        let contentLabel = NSTextField(labelWithString: preview + (message.content.count > 100 ? "..." : ""))
        contentLabel.font = NSFont.systemFont(ofSize: 12)
        contentLabel.textColor = message.isRead ? Catppuccin.subtext0 : Catppuccin.text
        contentLabel.lineBreakMode = .byTruncatingTail
        contentLabel.maximumNumberOfLines = 2
        cell.addArrangedSubview(contentLabel)

        return cell
    }

    private func createTimeCell(for message: DatabaseManager.InboxMessage) -> NSView {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relativeTime = formatter.localizedString(for: message.timestamp, relativeTo: Date())

        let label = NSTextField(labelWithString: relativeTime)
        label.font = NSFont.systemFont(ofSize: 10)
        label.textColor = Catppuccin.overlay0
        label.alignment = .right
        return label
    }
}

// MARK: - Inbox Row View

class InboxRowView: NSTableRowView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        Catppuccin.surface0.withAlphaComponent(0.3).setFill()
        let rowRect = bounds.insetBy(dx: 4, dy: 2)
        let path = NSBezierPath(roundedRect: rowRect, xRadius: 6, yRadius: 6)
        path.fill()

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
