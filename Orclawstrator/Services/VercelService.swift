import Foundation

/// Stub for Vercel CLI integration - to be implemented
class VercelService {
    static let shared = VercelService()
    private init() {}
    
    struct Deployment {
        var state: DeploymentState = .unknown
        var url: String?
    }
    
    enum DeploymentState {
        case ready
        case building
        case queued
        case error
        case unknown
        
        var buildStatus: BuildStatus {
            switch self {
            case .ready: return .ready
            case .building: return .building
            case .queued: return .building
            case .error: return .error
            case .unknown: return .none
            }
        }
    }
    
    struct VercelState {
        var latestDeployment: Deployment?
        var hasVercel: Bool = false
    }
    
    func getVercelState(for path: String) -> VercelState {
        // TODO: Implement vercel CLI integration
        return VercelState()
    }
}
