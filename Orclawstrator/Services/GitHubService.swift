import Foundation

/// Stub for GitHub CLI integration - to be implemented
class GitHubService {
    static let shared = GitHubService()
    private init() {}
    
    struct GitHubState {
        var issueCount: Int = 0
        var prCount: Int = 0
        var hasGitHub: Bool = false
    }
    
    func getGitHubState(for path: String) -> GitHubState {
        // TODO: Implement gh CLI integration
        return GitHubState()
    }
}
