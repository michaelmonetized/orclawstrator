import Foundation

// MARK: - Project Language

enum ProjectLanguage: String, CaseIterable {
    case swift = "swift"
    case typescript = "typescript"
    case javascript = "javascript"
    case rust = "rust"
    case c = "c"
    case cpp = "cpp"
    case python = "python"
    case ruby = "ruby"
    case go = "go"
    case terminal = "terminal"
    
    var icon: String {
        switch self {
        case .swift: return "🦅"
        case .typescript, .javascript: return "🔷"
        case .rust: return "🦀"
        case .c, .cpp: return "⚙️"
        case .python: return "🐍"
        case .ruby: return "💎"
        case .go: return "🐹"
        case .terminal: return "🖥️"
        }
    }
    
    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .typescript: return "TypeScript"
        case .javascript: return "JavaScript"
        case .rust: return "Rust"
        case .c: return "C"
        case .cpp: return "C++"
        case .python: return "Python"
        case .ruby: return "Ruby"
        case .go: return "Go"
        case .terminal: return "CLI"
        }
    }
}

// MARK: - Git State

struct GitState {
    var branches: [String] = []
    var activeBranch: String = "main"
    var untracked: Int = 0
    var staged: Int = 0
    var modified: Int = 0
    var hasRemote: Bool = false
    var lastCommitDate: Date?
    var lastMainCommitDate: Date?
    var firstCommitDate: Date?
    
    var branchCount: Int { branches.count }
    
    var ageString: String {
        guard let firstCommit = firstCommitDate else { return "-" }
        return formatTimeAgo(from: firstCommit)
    }
    
    var lastMainString: String {
        guard let lastMain = lastMainCommitDate else { return "-" }
        return formatTimeAgo(from: lastMain)
    }
    
    var lastBranchString: String {
        guard let lastCommit = lastCommitDate else { return "-" }
        return formatTimeAgo(from: lastCommit)
    }
    
    private func formatTimeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        
        if days > 365 {
            let years = days / 365
            let months = (days % 365) / 30
            return "\(years)y \(months)m"
        } else if days > 30 {
            let months = days / 30
            let remainingDays = days % 30
            return "\(months)m \(remainingDays)d"
        } else if days > 0 {
            return "\(days)d"
        } else {
            let hours = Int(interval / 3600)
            return hours > 0 ? "\(hours)h" : "<1h"
        }
    }
}

// MARK: - Build Status

enum BuildStatus: String {
    case ready = "Ready"
    case building = "Building"
    case queued = "Queued"
    case error = "Error"
    case none = "-"
    
    var color: String {
        switch self {
        case .ready: return "green"
        case .building: return "yellow"
        case .queued: return "blue"
        case .error: return "red"
        case .none: return "gray"
        }
    }
}

// MARK: - Project Model

class Project: Identifiable {
    let id: UUID
    var name: String
    var path: String
    var language: ProjectLanguage
    var gitState: GitState
    var agent: String?
    var issueCount: Int = 0
    var stackCount: Int = 0
    var prComments: Int = 0
    var buildStatus: BuildStatus = .none
    var hasWarning: Bool = false
    var warningMessage: String?
    
    // Integration flags
    var hasGitHub: Bool = false
    var hasGraphite: Bool = false
    var hasVercel: Bool = false
    
    init(name: String, path: String) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.language = .terminal
        self.gitState = GitState()
    }
    
    // Computed display properties
    var branchDisplay: String {
        if gitState.branchCount > 1 {
            return "\(gitState.activeBranch) +\(gitState.branchCount - 1)"
        }
        return gitState.activeBranch
    }
    
    var untrackedDisplay: String {
        return gitState.untracked > 0 ? "\(gitState.untracked)" : "-"
    }
    
    var stagedDisplay: String {
        return gitState.staged > 0 ? "\(gitState.staged)" : "-"
    }
    
    var issuesDisplay: String {
        return issueCount > 0 ? "\(issueCount)" : "-"
    }
    
    var stacksDisplay: String {
        return stackCount > 0 ? "\(stackCount)" : "-"
    }
    
    var commentsDisplay: String {
        return prComments > 0 ? "\(prComments)" : "-"
    }
}
