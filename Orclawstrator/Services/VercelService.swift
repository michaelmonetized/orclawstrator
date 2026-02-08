import AppKit
import Foundation

/// Vercel CLI integration for deployment status
class VercelService {
    static let shared = VercelService()
    private let shell = ShellExecutor.shared
    private let fileManager = FileManager.default
    
    private init() {}
    
    struct Deployment {
        var state: DeploymentState = .unknown
        var url: String?
        var projectName: String?
        var age: String?
    }
    
    enum DeploymentState: String {
        case ready = "Ready"
        case building = "Building"
        case queued = "Queued"
        case error = "Error"
        case canceled = "Canceled"
        case unknown = "Unknown"
        
        var buildStatus: BuildStatus {
            switch self {
            case .ready: return .ready
            case .building: return .building
            case .queued: return .building
            case .error: return .error
            case .canceled: return .error
            case .unknown: return .none
            }
        }
    }
    
    struct VercelState {
        var latestDeployment: Deployment?
        var hasVercel: Bool = false
        var projectName: String?
    }
    
    /// Get Vercel state for a project directory
    func getVercelState(for path: String) -> VercelState {
        var state = VercelState()
        
        // Check if project has Vercel configuration
        let hasVercelJson = fileManager.fileExists(atPath: (path as NSString).appendingPathComponent("vercel.json"))
        let hasVercelFolder = fileManager.fileExists(atPath: (path as NSString).appendingPathComponent(".vercel"))
        
        guard hasVercelJson || hasVercelFolder else {
            return state
        }
        
        state.hasVercel = true
        
        // Try to get project name from .vercel/project.json
        if hasVercelFolder {
            let projectJsonPath = (path as NSString).appendingPathComponent(".vercel/project.json")
            if let data = fileManager.contents(atPath: projectJsonPath),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["projectId"] as? String {
                state.projectName = name
            }
        }
        
        // Get deployment status using vercel ls
        // Format: vercel ls --yes outputs a table with columns:
        // Age | Deployment URL | State | Production?
        let lsResult = shell.run("vercel ls --yes 2>/dev/null | head -10", in: path)
        
        if lsResult.exitCode == 0 && !lsResult.output.isEmpty {
            state.latestDeployment = parseLatestDeployment(from: lsResult.output)
        }
        
        return state
    }
    
    /// Parse the latest deployment from vercel ls output
    private func parseLatestDeployment(from output: String) -> Deployment? {
        let lines = output.split(separator: "\n")
        
        // Find first data line (skip header if present)
        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and header
            if lineStr.isEmpty || lineStr.hasPrefix("Age") || lineStr.contains("─") {
                continue
            }
            
            // Parse deployment line
            // Format varies but typically: "2h" "https://proj-xxx.vercel.app" "Ready"
            // Or with columns: Age Status URL
            
            var deployment = Deployment()
            
            // Check for state keywords in the line
            let upperLine = lineStr.uppercased()
            if upperLine.contains("READY") || upperLine.contains("✓") {
                deployment.state = .ready
            } else if upperLine.contains("BUILDING") || upperLine.contains("⏳") {
                deployment.state = .building
            } else if upperLine.contains("ERROR") || upperLine.contains("✕") || upperLine.contains("FAILED") {
                deployment.state = .error
            } else if upperLine.contains("QUEUED") {
                deployment.state = .queued
            } else if upperLine.contains("CANCELED") {
                deployment.state = .canceled
            } else {
                // If we see a vercel URL, assume it's ready
                if lineStr.contains(".vercel.app") || lineStr.contains("https://") {
                    deployment.state = .ready
                }
            }
            
            // Extract URL if present
            if let urlRange = lineStr.range(of: "https://[^\\s]+", options: .regularExpression) {
                deployment.url = String(lineStr[urlRange])
            }
            
            // Extract age (typically first column)
            let components = lineStr.split(separator: " ").map { String($0) }
            if let first = components.first, first.contains("h") || first.contains("m") || first.contains("d") || first.contains("s") {
                deployment.age = first
            }
            
            return deployment
        }
        
        return nil
    }
    
    /// Open Vercel dashboard for the project
    func openDashboard(for path: String) {
        // Get project name from .vercel/project.json
        let projectJsonPath = (path as NSString).appendingPathComponent(".vercel/project.json")
        
        if let data = fileManager.contents(atPath: projectJsonPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let orgId = json["orgId"] as? String,
           let projectId = json["projectId"] as? String {
            // Vercel dashboard URL format
            let dashboardUrl = "https://vercel.com/\(orgId)/\(projectId)"
            if let url = URL(string: dashboardUrl) {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Fallback: open general Vercel dashboard
            if let url = URL(string: "https://vercel.com/dashboard") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// Open the latest deployment URL
    func openLatestDeployment(for path: String) {
        let state = getVercelState(for: path)
        if let url = state.latestDeployment?.url,
           let nsUrl = URL(string: url) {
            NSWorkspace.shared.open(nsUrl)
        }
    }
}
