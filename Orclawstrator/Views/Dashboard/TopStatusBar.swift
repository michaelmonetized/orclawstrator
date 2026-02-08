import Cocoa

/// Top status bar spanning full window width
/// Contains: Logo | Path pill | Warning | Status pills || Idle | Agents/Subs | Tokens
class TopStatusBar: NSView {
    
    // MARK: - UI Components
    
    // Left section
    private var logoLabel: NSTextField!
    private var pathPill: PillView!
    private var warningIcon: NSTextField!
    
    // Center section - status pills
    private var readyPill: StatusPillView!
    private var buildingPill: StatusPillView!
    private var errorPill: StatusPillView!
    
    // Right section
    private var idlePill: PillView!
    private var agentsPill: PillView!
    private var tokensPill: PillView!
    
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
        
        // === LEFT SECTION ===
        let leftStack = NSStackView()
        leftStack.orientation = .horizontal
        leftStack.spacing = 12
        leftStack.alignment = .centerY
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftStack)
        
        // Logo
        logoLabel = NSTextField(labelWithString: "🦞 orclawstrator")
        logoLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        logoLabel.textColor = Catppuccin.peach  // Orange like the mockup
        leftStack.addArrangedSubview(logoLabel)
        
        // Path pill
        pathPill = PillView(text: "~/Projects", count: 0, backgroundColor: Catppuccin.surface1, textColor: Catppuccin.subtext1)
        leftStack.addArrangedSubview(pathPill)
        
        // Warning icon
        warningIcon = NSTextField(labelWithString: "⚠")
        warningIcon.font = NSFont.systemFont(ofSize: 14)
        warningIcon.textColor = Catppuccin.yellow
        warningIcon.isHidden = true  // Show when there are warnings
        leftStack.addArrangedSubview(warningIcon)
        
        // === CENTER SECTION - Status Pills ===
        let centerStack = NSStackView()
        centerStack.orientation = .horizontal
        centerStack.spacing = 8
        centerStack.alignment = .centerY
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerStack)
        
        readyPill = StatusPillView(label: "Ready", count: 0, color: Catppuccin.green)
        buildingPill = StatusPillView(label: "Building", count: 0, color: Catppuccin.yellow)
        errorPill = StatusPillView(label: "Error", count: 0, color: Catppuccin.red)
        
        centerStack.addArrangedSubview(readyPill)
        centerStack.addArrangedSubview(buildingPill)
        centerStack.addArrangedSubview(errorPill)
        
        // === RIGHT SECTION ===
        let rightStack = NSStackView()
        rightStack.orientation = .horizontal
        rightStack.spacing = 8
        rightStack.alignment = .centerY
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightStack)
        
        // Idle count with icon
        idlePill = PillView(icon: "🌙", text: "02 Idle", backgroundColor: Catppuccin.surface1, textColor: Catppuccin.subtext1)
        rightStack.addArrangedSubview(idlePill)
        
        // Agents/Subs
        agentsPill = PillView(text: "04 Agents / 36 Subs", backgroundColor: Catppuccin.blue.withAlphaComponent(0.3), textColor: Catppuccin.blue)
        rightStack.addArrangedSubview(agentsPill)
        
        // Token usage
        tokensPill = PillView(text: "125k/200k Tokens", backgroundColor: Catppuccin.mauve.withAlphaComponent(0.3), textColor: Catppuccin.mauve)
        rightStack.addArrangedSubview(tokensPill)
        
        // Layout
        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateStats(projectCount: Int, buildStats: (ready: Int, building: Int, error: Int)) {
        pathPill.updateCount(projectCount)
        readyPill.updateCount(buildStats.ready)
        buildingPill.updateCount(buildStats.building)
        errorPill.updateCount(buildStats.error)
        
        // Show warning if there are errors
        warningIcon.isHidden = buildStats.error == 0
    }
    
    func updateAgentStats(agents: Int, subs: Int, idle: Int) {
        idlePill.updateText(String(format: "%02d Idle", idle))
        agentsPill.updateText(String(format: "%02d Agents / %02d Subs", agents, subs))
    }
    
    func updateTokenUsage(used: Int, total: Int) {
        let usedK = used / 1000
        let totalK = total / 1000
        tokensPill.updateText("\(usedK)k/\(totalK)k Tokens")
    }
    
    func setWarningVisible(_ visible: Bool) {
        warningIcon.isHidden = !visible
    }
}

// MARK: - Generic Pill View

class PillView: NSView {
    
    private var iconLabel: NSTextField?
    private var textLabel: NSTextField!
    private var countLabel: NSTextField?
    
    init(icon: String? = nil, text: String, count: Int? = nil, backgroundColor: NSColor, textColor: NSColor) {
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.backgroundColor = backgroundColor.cgColor
        layer?.cornerRadius = 12
        
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        // Icon (optional)
        if let icon = icon {
            iconLabel = NSTextField(labelWithString: icon)
            iconLabel?.font = NSFont.systemFont(ofSize: 11)
            stack.addArrangedSubview(iconLabel!)
        }
        
        // Text
        textLabel = NSTextField(labelWithString: text)
        textLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        textLabel.textColor = textColor
        stack.addArrangedSubview(textLabel)
        
        // Count badge (optional)
        if let count = count {
            countLabel = NSTextField(labelWithString: String(format: "%02d", count))
            countLabel?.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
            countLabel?.textColor = textColor
            countLabel?.wantsLayer = true
            countLabel?.layer?.backgroundColor = textColor.withAlphaComponent(0.2).cgColor
            countLabel?.layer?.cornerRadius = 8
            stack.addArrangedSubview(countLabel!)
        }
        
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
    
    func updateText(_ text: String) {
        textLabel.stringValue = text
    }
    
    func updateCount(_ count: Int) {
        if let countLabel = countLabel {
            countLabel.stringValue = String(format: "%02d", count)
        } else {
            // Update the text to include the count for path pill
            let basePart = textLabel.stringValue.components(separatedBy: " (").first ?? textLabel.stringValue
            textLabel.stringValue = "\(basePart) (\(count))"
        }
    }
}

// MARK: - Status Pill View (Colored status indicators)

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
