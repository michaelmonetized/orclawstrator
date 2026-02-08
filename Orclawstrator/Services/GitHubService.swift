import AppKit
import Foundation

/// GitHub CLI integration for issue and PR counts
class GitHubService {
    static let shared = GitHubService()
    private let shell = ShellExecutor.shared
    
    private init() {}
    
    struct GitHubState {
        var issueCount: Int = 0
        var prCount: Int = 0
        var hasGitHub: Bool = false
        var repoUrl: String?
    }
    
    /// Get GitHub state for a project directory
    func getGitHubState(for path: String) -> GitHubState {
        var state = GitHubState()
        
        // Check if this repo has a GitHub remote
        let remoteResult = shell.run("git remote get-url origin 2>/dev/null", in: path)
        guard remoteResult.exitCode == 0,
              remoteResult.output.contains("github.com") else {
            return state
        }
        
        state.hasGitHub = true
        state.repoUrl = parseGitHubUrl(from: remoteResult.output)
        
        // Get issue count using gh CLI
        let issueResult = shell.run("gh issue list --json number --limit 100 2>/dev/null", in: path)
        if issueResult.exitCode == 0 {
            state.issueCount = countJsonItems(issueResult.output)
        }
        
        // Get PR count using gh CLI  
        let prResult = shell.run("gh pr list --json number --limit 100 2>/dev/null", in: path)
        if prResult.exitCode == 0 {
            state.prCount = countJsonItems(prResult.output)
        }
        
        return state
    }
    
    /// Parse GitHub URL from remote
    private func parseGitHubUrl(from remote: String) -> String? {
        var url = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Convert git@github.com:user/repo.git to https://github.com/user/repo
        if url.hasPrefix("git@github.com:") {
            url = url.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
        }
        
        // Remove .git suffix
        if url.hasSuffix(".git") {
            url = String(url.dropLast(4))
        }
        
        return url
    }
    
    /// Count items in JSON array output
    private func countJsonItems(_ json: String) -> Int {
        // Simple approach: count objects in JSON array
        guard let data = json.data(using: .utf8) else { return 0 }
        
        do {
            if let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return array.count
            }
        } catch {
            // Fallback: count opening braces (each object has one)
            return json.filter { $0 == "{" }.count
        }
        
        return 0
    }
    
    /// Open the GitHub repo in browser
    func openInBrowser(for path: String) {
        let state = getGitHubState(for: path)
        guard let url = state.repoUrl, let nsUrl = URL(string: url) else { return }
        NSWorkspace.shared.open(nsUrl)
    }
    
    /// Open issues page in browser
    func openIssues(for path: String) {
        let state = getGitHubState(for: path)
        guard let url = state.repoUrl, let nsUrl = URL(string: url + "/issues") else { return }
        NSWorkspace.shared.open(nsUrl)
    }
    
    /// Open PRs page in browser
    func openPullRequests(for path: String) {
        let state = getGitHubState(for: path)
        guard let url = state.repoUrl, let nsUrl = URL(string: url + "/pulls") else { return }
        NSWorkspace.shared.open(nsUrl)
    }
}
