import Foundation

/// Scans directories for projects and detects their languages
class ProjectScanner {
    
    static let shared = ProjectScanner()
    private let gitService = GitService.shared
    // TODO: Add when services are implemented
    // private let gitHubService = GitHubService.shared
    // private let graphiteService = GraphiteService.shared
    // private let vercelService = VercelService.shared
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Scan a directory for projects
    func scanProjects(in directory: String, completion: @escaping ([Project]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let projects = self.scanProjectsSync(in: directory)
            
            DispatchQueue.main.async {
                completion(projects)
            }
        }
    }
    
    /// Synchronous project scan
    func scanProjectsSync(in directory: String) -> [Project] {
        let expandedPath = NSString(string: directory).expandingTildeInPath
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: expandedPath) else {
            return []
        }
        
        var projects: [Project] = []
        
        for item in contents {
            // Skip hidden directories
            if item.hasPrefix(".") { continue }
            
            let itemPath = (expandedPath as NSString).appendingPathComponent(item)
            var isDirectory: ObjCBool = false
            
            guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }
            
            // Check if it's a git repository
            guard gitService.isGitRepository(at: itemPath) else { continue }
            
            let project = Project(name: item, path: itemPath)
            
            // Detect language
            project.language = detectLanguage(at: itemPath)
            
            // Get git state
            project.gitState = gitService.getGitState(for: itemPath)
            
            // TODO: Implement when services are added
            // Get GitHub state (issues/PRs)
            // let gitHubState = gitHubService.getGitHubState(for: itemPath)
            // project.issueCount = gitHubState.issueCount
            // project.hasGitHub = gitHubState.hasGitHub
            
            // Get Graphite state (stacked PRs)
            // let graphiteState = graphiteService.getGraphiteState(for: itemPath)
            // project.stackCount = graphiteState.stackCount
            // project.prComments = graphiteState.commentCount
            // project.hasGraphite = graphiteState.hasGraphite
            
            // Get Vercel state (build status)
            // let vercelState = vercelService.getVercelState(for: itemPath)
            // if let deployment = vercelState.latestDeployment {
            //     project.buildStatus = deployment.state.buildStatus
            // }
            // project.hasVercel = vercelState.hasVercel
            
            // Check for warnings
            checkWarnings(for: project)
            
            projects.append(project)
        }
        
        // Sort by name
        return projects.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    /// Detect primary language of a project
    func detectLanguage(at path: String) -> ProjectLanguage {
        // Check in order of specificity
        if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("Package.swift")) {
            return .swift
        }
        
        if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("Cargo.toml")) {
            return .rust
        }
        
        if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("go.mod")) {
            return .go
        }
        
        if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("pyproject.toml")) ||
           fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("setup.py")) ||
           fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("requirements.txt")) {
            return .python
        }
        
        if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("Gemfile")) {
            return .ruby
        }
        
        if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("CMakeLists.txt")) ||
           fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("Makefile")) {
            // Check for .c or .cpp files
            if let files = try? fileManager.contentsOfDirectory(atPath: path) {
                for file in files {
                    if file.hasSuffix(".cpp") || file.hasSuffix(".cc") {
                        return .cpp
                    }
                    if file.hasSuffix(".c") || file.hasSuffix(".h") {
                        return .c
                    }
                }
            }
            return .c
        }
        
        // Check for TypeScript vs JavaScript
        if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("package.json")) {
            if fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("tsconfig.json")) {
                return .typescript
            }
            return .javascript
        }
        
        // Check for Xcode project (Swift iOS/macOS app)
        if let contents = try? fileManager.contentsOfDirectory(atPath: path) {
            for item in contents {
                if item.hasSuffix(".xcodeproj") || item.hasSuffix(".xcworkspace") {
                    return .swift
                }
            }
        }
        
        return .terminal
    }
    
    /// Check for warning conditions
    private func checkWarnings(for project: Project) {
        // Warning if too many untracked files
        if project.gitState.untracked > 10 {
            project.hasWarning = true
            project.warningMessage = "\(project.gitState.untracked) untracked files"
        }
        
        // Warning if no remote
        if !project.gitState.hasRemote {
            project.hasWarning = true
            project.warningMessage = "No remote configured"
        }
        
        // Warning if stale (no commits in 30+ days)
        if let lastCommit = project.gitState.lastCommitDate {
            let daysSinceCommit = Date().timeIntervalSince(lastCommit) / 86400
            if daysSinceCommit > 30 {
                project.hasWarning = true
                project.warningMessage = "Stale: \(Int(daysSinceCommit)) days since last commit"
            }
        }
    }
}
