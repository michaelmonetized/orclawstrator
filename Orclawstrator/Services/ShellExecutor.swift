import Foundation

/// Executes shell commands and returns output
class ShellExecutor {
    
    static let shared = ShellExecutor()
    
    private init() {}
    
    /// Run a shell command synchronously
    func run(_ command: String, in directory: String? = nil) -> (output: String, exitCode: Int32) {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        if let directory = directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }
        
        // Set up environment with user's PATH
        var env = ProcessInfo.processInfo.environment
        if let path = env["PATH"] {
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + path
        }
        process.environment = env
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ("Error: \(error.localizedDescription)", -1)
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return (output.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus)
    }
    
    /// Run a shell command asynchronously
    func runAsync(_ command: String, in directory: String? = nil, completion: @escaping (String, Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.run(command, in: directory)
            DispatchQueue.main.async {
                completion(result.output, result.exitCode)
            }
        }
    }
}
