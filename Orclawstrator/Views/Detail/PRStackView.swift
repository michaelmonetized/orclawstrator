import Cocoa

/// Popover view showing stacked PRs for a project
class PRStackPopover: NSPopover {

    private let project: Project
    private let stackView: PRStackContentView

    init(project: Project) {
        self.project = project
        self.stackView = PRStackContentView(project: project)
        super.init()

        self.contentViewController = NSViewController()
        self.contentViewController?.view = stackView
        self.behavior = .transient
        self.contentSize = NSSize(width: 400, height: 300)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Content view for the PR stack popover
class PRStackContentView: NSView {

    private var headerLabel: NSTextField!
    private var scrollView: NSScrollView!
    private var stackContainer: NSStackView!
    private var loadingLabel: NSTextField!

    private let project: Project
    private let shell = ShellExecutor.shared
    private let graphiteService = GraphiteService.shared

    init(project: Project) {
        self.project = project
        super.init(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        setupUI()
        loadStackInfo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = Catppuccin.base.cgColor

        // Header
        headerLabel = NSTextField(labelWithString: "PR Stack")
        headerLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        headerLabel.textColor = Catppuccin.text
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)

        // Loading indicator
        loadingLabel = NSTextField(labelWithString: "Loading stack...")
        loadingLabel.font = NSFont.systemFont(ofSize: 12)
        loadingLabel.textColor = Catppuccin.subtext0
        loadingLabel.alignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingLabel)

        // Scroll view
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isHidden = true
        addSubview(scrollView)

        // Stack container
        stackContainer = NSStackView()
        stackContainer.orientation = .vertical
        stackContainer.spacing = 8
        stackContainer.alignment = .leading
        stackContainer.translatesAutoresizingMaskIntoConstraints = false

        let clipView = NSClipView()
        clipView.documentView = stackContainer
        clipView.drawsBackground = false
        scrollView.contentView = clipView

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            loadingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            stackContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16)
        ])
    }

    private func loadStackInfo() {
        let projectPath = (project.path as NSString).expandingTildeInPath

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Get stack info from graphite
            let stackResult = self.shell.run("gt log short --stack 2>/dev/null", in: projectPath)
            let prInfos = self.parseStackAndFetchPRs(stackOutput: stackResult.output, projectPath: projectPath)

            DispatchQueue.main.async {
                self.displayStack(prInfos)
            }
        }
    }

    private func parseStackAndFetchPRs(stackOutput: String, projectPath: String) -> [PRInfo] {
        var prInfos: [PRInfo] = []
        let lines = stackOutput.split(separator: "\n")

        for line in lines {
            let lineStr = String(line)

            // Look for branch indicators
            if lineStr.contains("◯") || lineStr.contains("◉") || lineStr.contains("○") || lineStr.contains("●") {
                // Extract branch name
                let cleaned = lineStr
                    .replacingOccurrences(of: "◯", with: "")
                    .replacingOccurrences(of: "◉", with: "")
                    .replacingOccurrences(of: "○", with: "")
                    .replacingOccurrences(of: "●", with: "")
                    .replacingOccurrences(of: "│", with: "")
                    .replacingOccurrences(of: "├", with: "")
                    .replacingOccurrences(of: "└", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if !cleaned.isEmpty && cleaned != "main" && cleaned != "master" {
                    // Try to get PR info for this branch
                    let prResult = shell.run("gh pr view \(cleaned) --json number,title,state,url,additions,deletions 2>/dev/null", in: projectPath)
                    if prResult.exitCode == 0, let prData = parsePRJson(prResult.output) {
                        prInfos.append(PRInfo(
                            branch: cleaned,
                            number: prData.number,
                            title: prData.title,
                            state: prData.state,
                            url: prData.url,
                            additions: prData.additions,
                            deletions: prData.deletions
                        ))
                    } else {
                        prInfos.append(PRInfo(branch: cleaned, number: nil, title: nil, state: nil, url: nil, additions: 0, deletions: 0))
                    }
                }
            }
        }

        return prInfos
    }

    private struct PRJsonData {
        let number: Int
        let title: String
        let state: String
        let url: String
        let additions: Int
        let deletions: Int
    }

    private func parsePRJson(_ json: String) -> PRJsonData? {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let number = dict["number"] as? Int,
              let title = dict["title"] as? String,
              let state = dict["state"] as? String,
              let url = dict["url"] as? String else {
            return nil
        }

        return PRJsonData(
            number: number,
            title: title,
            state: state,
            url: url,
            additions: dict["additions"] as? Int ?? 0,
            deletions: dict["deletions"] as? Int ?? 0
        )
    }

    private func displayStack(_ prInfos: [PRInfo]) {
        loadingLabel.isHidden = true
        scrollView.isHidden = false

        if prInfos.isEmpty {
            let emptyLabel = NSTextField(labelWithString: "No stacked PRs found")
            emptyLabel.font = NSFont.systemFont(ofSize: 12)
            emptyLabel.textColor = Catppuccin.subtext0
            stackContainer.addArrangedSubview(emptyLabel)
            return
        }

        headerLabel.stringValue = "PR Stack (\(prInfos.count) branches)"

        for (index, pr) in prInfos.enumerated() {
            let prView = createPRRow(pr: pr, index: index, total: prInfos.count)
            stackContainer.addArrangedSubview(prView)
        }
    }

    private func createPRRow(pr: PRInfo, index: Int, total: Int) -> NSView {
        let row = NSView()
        row.wantsLayer = true
        row.layer?.backgroundColor = Catppuccin.surface0.withAlphaComponent(0.5).cgColor
        row.layer?.cornerRadius = 6
        row.translatesAutoresizingMaskIntoConstraints = false

        // Stack position indicator
        let positionLabel = NSTextField(labelWithString: index == total - 1 ? "└" : "├")
        positionLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        positionLabel.textColor = Catppuccin.blue
        positionLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(positionLabel)

        // Branch name
        let branchLabel = NSTextField(labelWithString: pr.branch)
        branchLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        branchLabel.textColor = Catppuccin.mauve
        branchLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(branchLabel)

        // PR info
        let prTitleLabel: NSTextField
        if let number = pr.number, let title = pr.title {
            prTitleLabel = NSTextField(labelWithString: "#\(number): \(title)")
            prTitleLabel.textColor = Catppuccin.text
        } else {
            prTitleLabel = NSTextField(labelWithString: "No PR")
            prTitleLabel.textColor = Catppuccin.overlay0
        }
        prTitleLabel.font = NSFont.systemFont(ofSize: 11)
        prTitleLabel.lineBreakMode = .byTruncatingTail
        prTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(prTitleLabel)

        // Diff stats
        let diffLabel = NSTextField(labelWithString: "+\(pr.additions) -\(pr.deletions)")
        diffLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        diffLabel.textColor = Catppuccin.subtext0
        diffLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(diffLabel)

        // State badge
        if let state = pr.state {
            let stateBadge = NSTextField(labelWithString: state.uppercased())
            stateBadge.font = NSFont.systemFont(ofSize: 9, weight: .bold)
            stateBadge.textColor = state == "OPEN" ? Catppuccin.green : (state == "MERGED" ? Catppuccin.mauve : Catppuccin.red)
            stateBadge.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(stateBadge)

            NSLayoutConstraint.activate([
                stateBadge.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -8),
                stateBadge.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 50),

            positionLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
            positionLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            branchLabel.leadingAnchor.constraint(equalTo: positionLabel.trailingAnchor, constant: 8),
            branchLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),

            prTitleLabel.leadingAnchor.constraint(equalTo: branchLabel.leadingAnchor),
            prTitleLabel.topAnchor.constraint(equalTo: branchLabel.bottomAnchor, constant: 2),
            prTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor, constant: -60),

            diffLabel.leadingAnchor.constraint(equalTo: branchLabel.trailingAnchor, constant: 12),
            diffLabel.centerYAnchor.constraint(equalTo: branchLabel.centerYAnchor)
        ])

        // Make clickable if has URL
        if let url = pr.url {
            let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(prClicked(_:)))
            row.addGestureRecognizer(clickGesture)
            row.toolTip = url
        }

        return row
    }

    @objc private func prClicked(_ sender: NSClickGestureRecognizer) {
        if let view = sender.view, let urlString = view.toolTip, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - PR Info Model

struct PRInfo {
    let branch: String
    let number: Int?
    let title: String?
    let state: String?
    let url: String?
    let additions: Int
    let deletions: Int
}
