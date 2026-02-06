import Foundation

/// Service for Git CLI operations
class GitService {
    
    static let shared = GitService()
    private let shell = ShellExecutor.shared
    
    private init() {}
    
    /// Check if a directory is a git repository
    func isGitRepository(at path: String) -> Bool {
        let result = shell.run("git rev-parse --git-dir 2>/dev/null", in: path)
        return result.exitCode == 0
    }
    
    /// Get full git state for a project
    func getGitState(for path: String) -> GitState {
        var state = GitState()
        
        // Get current branch
        let branchResult = shell.run("git branch --show-current 2>/dev/null", in: path)
        if branchResult.exitCode == 0 && !branchResult.output.isEmpty {
            state.activeBranch = branchResult.output
        }
        
        // Get all branches
        let allBranchesResult = shell.run("git branch --list 2>/dev/null | wc -l", in: path)
        if let count = Int(allBranchesResult.output.trimmingCharacters(in: .whitespaces)) {
            state.branches = Array(repeating: "", count: count)
        }
        
        // Get status (porcelain format)
        let statusResult = shell.run("git status --porcelain 2>/dev/null", in: path)
        if statusResult.exitCode == 0 {
            let lines = statusResult.output.split(separator: "\n")
            for line in lines {
                if line.hasPrefix("??") {
                    state.untracked += 1
                } else if line.hasPrefix("A ") || line.hasPrefix("M ") || line.hasPrefix("D ") {
                    state.staged += 1
                } else if line.hasPrefix(" M") || line.hasPrefix(" D") {
                    state.modified += 1
                }
            }
        }
        
        // Check for remote
        let remoteResult = shell.run("git remote 2>/dev/null", in: path)
        state.hasRemote = !remoteResult.output.isEmpty
        
        // Get last commit date on current branch
        let lastCommitResult = shell.run("git log -1 --format=%ct 2>/dev/null", in: path)
        if let timestamp = Double(lastCommitResult.output) {
            state.lastCommitDate = Date(timeIntervalSince1970: timestamp)
        }
        
        // Get last commit date on main/master
        let mainBranchResult = shell.run("git log -1 --format=%ct main 2>/dev/null || git log -1 --format=%ct master 2>/dev/null", in: path)
        if let timestamp = Double(mainBranchResult.output) {
            state.lastMainCommitDate = Date(timeIntervalSince1970: timestamp)
        }
        
        // Get first commit date (age)
        let firstCommitResult = shell.run("git log --reverse --format=%ct 2>/dev/null | head -1", in: path)
        if let timestamp = Double(firstCommitResult.output) {
            state.firstCommitDate = Date(timeIntervalSince1970: timestamp)
        }
        
        return state
    }
    
    /// Get list of branch names
    func getBranches(for path: String) -> [String] {
        let result = shell.run("git branch --list --format='%(refname:short)' 2>/dev/null", in: path)
        guard result.exitCode == 0 else { return [] }
        return result.output.split(separator: "\n").map { String($0) }
    }
}
