import Foundation

/// Stub for Graphite CLI integration - to be implemented
class GraphiteService {
    static let shared = GraphiteService()
    private init() {}
    
    struct GraphiteState {
        var stackCount: Int = 0
        var commentCount: Int = 0
        var hasGraphite: Bool = false
    }
    
    func getGraphiteState(for path: String) -> GraphiteState {
        // TODO: Implement gt CLI integration
        return GraphiteState()
    }
}
