import Foundation

/// Service for OpenClaw Gateway integration
/// Handles WebSocket connection for real-time agent output and REST API calls
class OpenClawService {
    
    static let shared = OpenClawService()
    
    // MARK: - Configuration
    
    private let gatewayHost = "localhost"
    private let gatewayPort = 3377
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession!
    
    // MARK: - State
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onConnectionStateChanged?(self.connectionState)
            }
        }
    }
    
    // MARK: - Callbacks
    
    var onConnectionStateChanged: ((ConnectionState) -> Void)?
    var onAgentMessage: ((AgentMessage) -> Void)?
    var onSessionUpdate: ((SessionInfo) -> Void)?
    
    // MARK: - Types
    
    struct GatewayStatus: Decodable {
        let status: String
        let version: String?
        let uptime: Double?
        let sessions: Int?
    }
    
    struct SessionInfo: Decodable {
        let id: String
        let label: String?
        let model: String?
        let status: String
        let tokensUsed: Int?
        let createdAt: String?
    }
    
    struct SessionsResponse: Decodable {
        let sessions: [SessionInfo]
    }
    
    struct AgentMessage {
        let sessionId: String
        let type: MessageType
        let content: String
        let timestamp: Date
        
        enum MessageType: String {
            case text
            case tool
            case thinking
            case error
            case system
        }
    }
    
    struct UsageStats {
        var totalTokens: Int = 0
        var tokenLimit: Int = 200000
        var activeSessions: Int = 0
        var subagents: Int = 0
        var idleSessions: Int = 0
    }
    
    // MARK: - Init
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }
    
    // MARK: - REST API
    
    private var baseURL: URL {
        URL(string: "http://\(gatewayHost):\(gatewayPort)")!
    }
    
    /// Check if Gateway is running
    func checkStatus(completion: @escaping (GatewayStatus?) -> Void) {
        let url = baseURL.appendingPathComponent("status")
        
        let task = session.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let status = try? JSONDecoder().decode(GatewayStatus.self, from: data)
            DispatchQueue.main.async { completion(status) }
        }
        task.resume()
    }
    
    /// Get all active sessions
    func getSessions(completion: @escaping ([SessionInfo]) -> Void) {
        let url = baseURL.appendingPathComponent("sessions")
        
        let task = session.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            if let response = try? JSONDecoder().decode(SessionsResponse.self, from: data) {
                DispatchQueue.main.async { completion(response.sessions) }
            } else if let sessions = try? JSONDecoder().decode([SessionInfo].self, from: data) {
                DispatchQueue.main.async { completion(sessions) }
            } else {
                DispatchQueue.main.async { completion([]) }
            }
        }
        task.resume()
    }
    
    /// Get usage statistics
    func getUsageStats(completion: @escaping (UsageStats) -> Void) {
        getSessions { sessions in
            var stats = UsageStats()
            
            stats.activeSessions = sessions.filter { $0.status == "active" || $0.status == "working" }.count
            stats.idleSessions = sessions.filter { $0.status == "idle" }.count
            stats.subagents = sessions.filter { $0.label?.contains("subagent") ?? false }.count
            stats.totalTokens = sessions.compactMap { $0.tokensUsed }.reduce(0, +)
            
            completion(stats)
        }
    }
    
    /// Send a message to a session
    func sendMessage(_ message: String, to sessionId: String, completion: @escaping (Bool) -> Void) {
        let url = baseURL.appendingPathComponent("sessions/\(sessionId)/message")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["message": message]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = session.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            DispatchQueue.main.async { completion(success) }
        }
        task.resume()
    }
    
    // MARK: - WebSocket
    
    /// Connect to Gateway WebSocket for real-time updates
    func connect() {
        guard case .disconnected = connectionState else { return }
        
        connectionState = .connecting
        
        let wsURL = URL(string: "ws://\(gatewayHost):\(gatewayPort)/ws")!
        webSocket = session.webSocketTask(with: wsURL)
        webSocket?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // Connection is considered established once we receive first message or after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if case .connecting = self?.connectionState {
                self?.connectionState = .connected
            }
        }
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        connectionState = .disconnected
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                self?.receiveMessage()  // Continue receiving
                
            case .failure(let error):
                self?.connectionState = .error(error.localizedDescription)
                // Try to reconnect after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.connectionState = .disconnected
                    self?.connect()
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseWebSocketMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseWebSocketMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func parseWebSocketMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Handle different message types
        if let type = json["type"] as? String {
            switch type {
            case "connected":
                connectionState = .connected
                
            case "message", "output", "text":
                if let sessionId = json["sessionId"] as? String ?? json["session"] as? String,
                   let content = json["content"] as? String ?? json["text"] as? String ?? json["data"] as? String {
                    
                    let messageType: AgentMessage.MessageType
                    if let subtype = json["subtype"] as? String {
                        messageType = AgentMessage.MessageType(rawValue: subtype) ?? .text
                    } else {
                        messageType = .text
                    }
                    
                    let agentMessage = AgentMessage(
                        sessionId: sessionId,
                        type: messageType,
                        content: content,
                        timestamp: Date()
                    )
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.onAgentMessage?(agentMessage)
                    }
                }
                
            case "session_update", "session":
                if let sessionData = json["session"] as? [String: Any] ?? json["data"] as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: sessionData),
                   let sessionInfo = try? JSONDecoder().decode(SessionInfo.self, from: jsonData) {
                    DispatchQueue.main.async { [weak self] in
                        self?.onSessionUpdate?(sessionInfo)
                    }
                }
                
            case "error":
                if let errorMsg = json["message"] as? String ?? json["error"] as? String {
                    connectionState = .error(errorMsg)
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Get connection state description
    var connectionStateDescription: String {
        switch connectionState {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }
    
    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }
}
