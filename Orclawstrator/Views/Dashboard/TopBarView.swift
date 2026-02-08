import Cocoa

class TopBarView: NSView {
    
    // MARK: - UI Components
    private var logoLabel: NSTextField!
    private var projectsBadge: NSView!
    private var projectsLabel: NSTextField!
    
    // Status pills
    private var readyPill: StatusPillView!
    private var buildingPill: StatusPillView!
    private var errorPill: StatusPillView!
    
    // Right side stats
    private var idleLabel: NSTextField!
    private var agentStatsLabel: NSTextField!
    private var tokenUsageLabel: NSTextField!
    
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
        layer?.backgroundColor = Catppuccin.surface0.withAlphaComponent(0.6).cgColor
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        layer?.borderColor = Catppuccin.surface1.withAlphaComponent(0.3).cgColor
        
        // Left section - Logo + Projects badge
        let leftStack = NSStackView()
        leftStack.orientation = .horizontal
        leftStack.spacing = 12
        leftStack.alignment = .centerY
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftStack)
        
        // Logo
        logoLabel = NSTextField(labelWithString: "🦞 orclawstrator")
        logoLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        logoLabel.textColor = Catppuccin.text
        leftStack.addArrangedSubview(logoLabel)
        
        // Projects badge
        projectsBadge = createBadge(text: "~/Projects (0)", color: Catppuccin.surface1)
        leftStack.addArrangedSubview(projectsBadge)
        
        // Center section - Status pills
        let centerStack = NSStackView()
        centerStack.orientation = .horizontal
        centerStack.spacing = 8
        centerStack.alignment = .centerY
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerStack)
        
        readyPill = StatusPillView(label: "Ready", count: 0, color: Catppuccin.green)
        buildingPill = StatusPillView(label: "Building", count: 0, color: Catppuccin.peach)
        errorPill = StatusPillView(label: "Error", count: 0, color: Catppuccin.red)
        
        centerStack.addArrangedSubview(readyPill)
        centerStack.addArrangedSubview(buildingPill)
        centerStack.addArrangedSubview(errorPill)
        
        // Right section - Agent stats
        let rightStack = NSStackView()
        rightStack.orientation = .horizontal
        rightStack.spacing = 16
        rightStack.alignment = .centerY
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightStack)
        
        idleLabel = createStatLabel(text: "02 Idle")
        agentStatsLabel = createStatLabel(text: "04 Agents / 36 Subs")
        tokenUsageLabel = createStatLabel(text: "125k/200k Tokens")
        
        rightStack.addArrangedSubview(idleLabel)
        rightStack.addArrangedSubview(createSeparator())
        rightStack.addArrangedSubview(agentStatsLabel)
        rightStack.addArrangedSubview(createSeparator())
        rightStack.addArrangedSubview(tokenUsageLabel)
        
        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func createBadge(text: String, color: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = color.withAlphaComponent(0.3).cgColor
        container.layer?.cornerRadius = 6
        
        projectsLabel = NSTextField(labelWithString: text)
        projectsLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        projectsLabel.textColor = Catppuccin.subtext1
        projectsLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(projectsLabel)
        
        NSLayoutConstraint.activate([
            projectsLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            projectsLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            projectsLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            projectsLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
        
        return container
    }
    
    private func createStatLabel(text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        label.textColor = Catppuccin.subtext0
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }
    
    private func createSeparator() -> NSView {
        let sep = NSView()
        sep.wantsLayer = true
        sep.layer?.backgroundColor = Catppuccin.surface2.withAlphaComponent(0.5).cgColor
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 1).isActive = true
        sep.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return sep
    }
    
    // MARK: - Public Methods
    func updateStats(projectCount: Int, buildStats: (ready: Int, building: Int, error: Int)) {
        projectsLabel.stringValue = "~/Projects (\(projectCount))"
        readyPill.updateCount(buildStats.ready)
        buildingPill.updateCount(buildStats.building)
        errorPill.updateCount(buildStats.error)
    }
    
    func updateAgentStats(agents: Int, subs: Int, idle: Int) {
        idleLabel.stringValue = String(format: "%02d Idle", idle)
        agentStatsLabel.stringValue = String(format: "%02d Agents / %02d Subs", agents, subs)
    }
    
    func updateTokenUsage(used: Int, total: Int) {
        let usedK = used / 1000
        let totalK = total / 1000
        tokenUsageLabel.stringValue = "\(usedK)k/\(totalK)k Tokens"
    }
}

// MARK: - Status Pill View

class StatusPillView: NSView {
    
    private var countLabel: NSTextField!
    private var textLabel: NSTextField!
    private var pillColor: NSColor
    
    init(label: String, count: Int, color: NSColor) {
        self.pillColor = color
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.backgroundColor = color.withAlphaComponent(0.2).cgColor
        layer?.cornerRadius = 12
        layer?.borderWidth = 1
        layer?.borderColor = color.withAlphaComponent(0.4).cgColor
        
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        countLabel = NSTextField(labelWithString: String(format: "%02d", count))
        countLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        countLabel.textColor = color
        
        textLabel = NSTextField(labelWithString: label)
        textLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        textLabel.textColor = color.withAlphaComponent(0.9)
        
        stack.addArrangedSubview(countLabel)
        stack.addArrangedSubview(textLabel)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func updateCount(_ count: Int) {
        countLabel.stringValue = String(format: "%02d", count)
    }
}
