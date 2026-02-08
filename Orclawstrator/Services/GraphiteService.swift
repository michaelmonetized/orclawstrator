import AppKit
import Foundation

/// Graphite CLI integration for stacked PR info
class GraphiteService {
    static let shared = GraphiteService()
    private let shell = ShellExecutor.shared
    
    private init() {}
    
    struct GraphiteState {
        var stackCount: Int = 0
        var currentStackPosition: Int = 0
        var hasGraphite: Bool = false
        var stackBranches: [String] = []
    }
    
    /// Get Graphite state for a project directory
    func getGraphiteState(for path: String) -> GraphiteState {
        var state = GraphiteState()
        
        // Check if gt CLI is available and repo is initialized with Graphite
        // Running gt log short --stack will fail if not a Graphite repo
        let stackResult = shell.run("gt log short --stack 2>/dev/null", in: path)
        
        guard stackResult.exitCode == 0 else {
            return state
        }
        
        state.hasGraphite = true
        
        // Parse the stack output
        // Format is typically:
        // ◯ branch-name (n commits)
        // │ 
        // ◉ current-branch (n commits)  <- current position has ◉
        // │
        // ◯ another-branch
        
        let lines = stackResult.output.split(separator: "\n")
        var branches: [String] = []
        var currentPosition = 0
        var position = 0
        
        for line in lines {
            let lineStr = String(line)
            
            // Skip separator lines
            if lineStr.trimmingCharacters(in: .whitespaces) == "│" ||
               lineStr.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            
            // Check if it's a branch line (starts with ◯ or ◉)
            if lineStr.contains("◯") || lineStr.contains("◉") || lineStr.contains("○") || lineStr.contains("●") {
                // Extract branch name
                var branchName = lineStr
                    .replacingOccurrences(of: "◯", with: "")
                    .replacingOccurrences(of: "◉", with: "")
                    .replacingOccurrences(of: "○", with: "")
                    .replacingOccurrences(of: "●", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                // Remove commit count if present (e.g., "(2 commits)")
                if let parenIndex = branchName.firstIndex(of: "(") {
                    branchName = String(branchName[..<parenIndex]).trimmingCharacters(in: .whitespaces)
                }
                
                if !branchName.isEmpty {
                    branches.append(branchName)
                    
                    // Check if this is the current branch (marked with ◉ or ●)
                    if lineStr.contains("◉") || lineStr.contains("●") {
                        currentPosition = position
                    }
                    position += 1
                }
            }
        }
        
        state.stackBranches = branches
        state.stackCount = branches.count
        state.currentStackPosition = currentPosition
        
        return state
    }
    
    /// Get number of stacks (not just branches in current stack)
    func getTotalStacks(for path: String) -> Int {
        // gt stack list shows all stacks
        let result = shell.run("gt stack list 2>/dev/null | grep -c '^'", in: path)
        if result.exitCode == 0, let count = Int(result.output.trimmingCharacters(in: .whitespaces)) {
            return count
        }
        return 0
    }
    
    /// Open Graphite dashboard for the repo
    func openDashboard(for path: String) {
        // Get remote URL to determine repo
        let remoteResult = shell.run("git remote get-url origin 2>/dev/null", in: path)
        guard remoteResult.exitCode == 0 else { return }
        
        var remote = remoteResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse owner/repo from remote
        // Format: git@github.com:owner/repo.git or https://github.com/owner/repo.git
        if remote.hasPrefix("git@github.com:") {
            remote = remote.replacingOccurrences(of: "git@github.com:", with: "")
        } else if remote.hasPrefix("https://github.com/") {
            remote = remote.replacingOccurrences(of: "https://github.com/", with: "")
        }
        
        if remote.hasSuffix(".git") {
            remote = String(remote.dropLast(4))
        }
        
        // Graphite dashboard URL
        let dashboardUrl = "https://app.graphite.dev/github/pr/\(remote)"
        if let url = URL(string: dashboardUrl) {
            NSWorkspace.shared.open(url)
        }
    }
}
