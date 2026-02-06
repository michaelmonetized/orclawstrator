import Cocoa

class TopBarView: NSView {
    
    // MARK: - UI Components
    private var projectsLabel: NSTextField!
    private var buildStatsLabel: NSTextField!
    private var agentStatsLabel: NSTextField!
    private var tokenUsageLabel: NSTextField!
    private var refreshButton: NSButton!
    
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
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        layer?.cornerRadius = 8
        
        // Main stack view
        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .horizontal
        stackView.spacing = 24
        stackView.distribution = .fill
        stackView.alignment = .centerY
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Projects count
        projectsLabel = createStatLabel(text: "~/Projects (0)")
        stackView.addArrangedSubview(projectsLabel)
        
        // Separator
        stackView.addArrangedSubview(createSeparator())
        
        // Build stats
        buildStatsLabel = createStatLabel(text: "-- Ready / -- Building / -- Error")
        stackView.addArrangedSubview(buildStatsLabel)
        
        // Separator
        stackView.addArrangedSubview(createSeparator())
        
        // Agent stats
        agentStatsLabel = createStatLabel(text: "0 Agents / 0 Subs")
        stackView.addArrangedSubview(agentStatsLabel)
        
        // Separator
        stackView.addArrangedSubview(createSeparator())
        
        // Token usage
        tokenUsageLabel = createStatLabel(text: "0k/200k Tokens")
        stackView.addArrangedSubview(tokenUsageLabel)
        
        // Flexible space
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(spacer)
        
        // Refresh button
        refreshButton = NSButton(title: "⟳ Refresh", target: nil, action: #selector(DashboardViewController.refreshProjects))
        refreshButton.bezelStyle = .inline
        refreshButton.contentTintColor = .systemTeal
        stackView.addArrangedSubview(refreshButton)
    }
    
    private func createStatLabel(text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        label.textColor = NSColor.white.withAlphaComponent(0.8)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }
    
    private func createSeparator() -> NSView {
        let separator = NSBox()
        separator.boxType = .separator
        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    // MARK: - Public Methods
    func updateStats(projectCount: Int, buildStats: (ready: Int, building: Int, error: Int)) {
        projectsLabel.stringValue = "~/Projects (\(projectCount))"
        buildStatsLabel.stringValue = String(format: "%02d Ready / %02d Building / %02d Error",
                                             buildStats.ready, buildStats.building, buildStats.error)
    }
    
    func updateAgentStats(agents: Int, subs: Int) {
        agentStatsLabel.stringValue = "\(agents) Agents / \(subs) Subs"
    }
    
    func updateTokenUsage(used: Int, total: Int) {
        let usedK = used / 1000
        let totalK = total / 1000
        tokenUsageLabel.stringValue = "\(usedK)k/\(totalK)k Tokens"
    }
}
