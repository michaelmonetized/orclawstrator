import Cocoa

/// Bottom status bar spanning full window width
/// LEFT: "Connected | Idle | agent main | session:main"
/// RIGHT: "orclawstrator-g-agent-main-main | anthropic/claude-opus-4.6 | claude-code"
class BottomStatusBar: NSView {
    
    // MARK: - UI Components
    
    private var statusDot: NSView!
    private var leftLabel: NSTextField!
    private var rightLabel: NSTextField!
    
    private let openClawService = OpenClawService.shared
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        setupConnectionObserver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConnectionObserver()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = Catppuccin.mantle.withAlphaComponent(0.7).cgColor
        
        // Status indicator dot
        statusDot = NSView()
        statusDot.wantsLayer = true
        statusDot.layer?.backgroundColor = Catppuccin.green.cgColor
        statusDot.layer?.cornerRadius = 4
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusDot)
        
        // Left side label
        leftLabel = NSTextField(labelWithString: "Connected | Idle | agent main | session:main")
        leftLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        leftLabel.textColor = Catppuccin.subtext0
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftLabel)
        
        // Right side label
        rightLabel = NSTextField(labelWithString: "orclawstrator-g-agent-main-main | anthropic/claude-opus-4.6 | claude-code")
        rightLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        rightLabel.textColor = Catppuccin.overlay1
        rightLabel.alignment = .right
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightLabel)
        
        NSLayoutConstraint.activate([
            // Status dot on the left
            statusDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),
            
            // Left label
            leftLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            leftLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Right label
            rightLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Initial update
        updateStatus()
    }
    
    private func setupConnectionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectionChange(_:)),
            name: NSNotification.Name("OpenClawConnectionChanged"),
            object: nil
        )
        
        // Update on session changes too
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatus),
            name: NSNotification.Name("AgentMessageReceived"),
            object: nil
        )
    }
    
    @objc private func handleConnectionChange(_ notification: Notification) {
        updateStatus()
    }
    
    @objc private func updateStatus() {
        let connected = openClawService.isConnected
        
        // Update dot color
        statusDot.layer?.backgroundColor = connected ? Catppuccin.green.cgColor : Catppuccin.red.cgColor
        
        // Update left label
        let connectionState = connected ? "Connected" : "Disconnected"
        let agentState = "Idle"  // TODO: Get from service
        let agentName = "agent main"
        let sessionName = "session:main"
        
        leftLabel.stringValue = "\(connectionState) | \(agentState) | \(agentName) | \(sessionName)"
        
        // Update right label (model info)
        // This could be fetched from OpenClawService
        rightLabel.stringValue = "orclawstrator-g-agent-main-main | anthropic/claude-opus-4 | claude-code"
    }
    
    func setConnected(_ connected: Bool) {
        statusDot.layer?.backgroundColor = connected ? Catppuccin.green.cgColor : Catppuccin.red.cgColor
    }
    
    func setLeftStatus(_ status: String) {
        leftLabel.stringValue = status
    }
    
    func setRightStatus(_ status: String) {
        rightLabel.stringValue = status
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
