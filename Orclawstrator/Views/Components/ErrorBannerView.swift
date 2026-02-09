import Cocoa

/// Global error banner that slides in from top
/// Usage: ErrorBanner.shared.show(message: "Something went wrong")
class ErrorBanner {

    static let shared = ErrorBanner()

    private var bannerWindow: NSWindow?
    private var dismissTimer: Timer?

    private init() {}

    /// Show an error message
    func show(message: String, type: BannerType = .error, duration: TimeInterval = 5.0) {
        DispatchQueue.main.async { [weak self] in
            self?.dismissTimer?.invalidate()
            self?.bannerWindow?.orderOut(nil)

            guard let screen = NSScreen.main else { return }

            let bannerHeight: CGFloat = 44
            let bannerWidth: CGFloat = min(500, screen.visibleFrame.width - 40)
            let x = screen.visibleFrame.midX - bannerWidth / 2
            let y = screen.visibleFrame.maxY - bannerHeight - 20

            let window = NSWindow(
                contentRect: NSRect(x: x, y: y + 60, width: bannerWidth, height: bannerHeight),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
            window.hasShadow = true
            window.ignoresMouseEvents = false

            let contentView = BannerContentView(message: message, type: type)
            contentView.onDismiss = { [weak self] in
                self?.dismiss()
            }
            window.contentView = contentView

            self?.bannerWindow = window
            window.orderFront(nil)

            // Animate slide down
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(
                    NSRect(x: x, y: y, width: bannerWidth, height: bannerHeight),
                    display: true
                )
            }

            // Auto dismiss
            self?.dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.dismiss()
            }
        }
    }

    /// Show a success message
    func showSuccess(_ message: String) {
        show(message: message, type: .success, duration: 3.0)
    }

    /// Show a warning message
    func showWarning(_ message: String) {
        show(message: message, type: .warning, duration: 4.0)
    }

    /// Show an error message
    func showError(_ message: String) {
        show(message: message, type: .error, duration: 5.0)
    }

    /// Dismiss the banner
    func dismiss() {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.bannerWindow else { return }

            self?.dismissTimer?.invalidate()

            // Animate slide up
            let currentFrame = window.frame
            let targetY = currentFrame.origin.y + 60

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                window.animator().setFrame(
                    NSRect(x: currentFrame.origin.x, y: targetY, width: currentFrame.width, height: currentFrame.height),
                    display: true
                )
            }, completionHandler: {
                window.orderOut(nil)
                self?.bannerWindow = nil
            })
        }
    }

    enum BannerType {
        case error
        case warning
        case success
        case info

        var backgroundColor: NSColor {
            switch self {
            case .error: return Catppuccin.red
            case .warning: return Catppuccin.peach
            case .success: return Catppuccin.green
            case .info: return Catppuccin.blue
            }
        }

        var icon: String {
            switch self {
            case .error: return "❌"
            case .warning: return "⚠️"
            case .success: return "✅"
            case .info: return "ℹ️"
            }
        }
    }
}

// MARK: - Banner Content View

private class BannerContentView: NSView {

    var onDismiss: (() -> Void)?

    init(message: String, type: ErrorBanner.BannerType) {
        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = type.backgroundColor.withAlphaComponent(0.95).cgColor
        layer?.cornerRadius = 8

        // Icon
        let iconLabel = NSTextField(labelWithString: type.icon)
        iconLabel.font = NSFont.systemFont(ofSize: 16)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconLabel)

        // Message
        let messageLabel = NSTextField(labelWithString: message)
        messageLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = .white
        messageLabel.lineBreakMode = .byTruncatingTail
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)

        // Dismiss button
        let dismissButton = NSButton(title: "✕", target: self, action: #selector(dismissClicked))
        dismissButton.bezelStyle = .inline
        dismissButton.isBordered = false
        dismissButton.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        dismissButton.contentTintColor = .white.withAlphaComponent(0.8)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dismissButton)

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            messageLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: dismissButton.leadingAnchor, constant: -8),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            dismissButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func dismissClicked() {
        onDismiss?()
    }
}
