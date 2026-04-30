import Foundation

/// Monitors whether the Vibe CLI process is currently running
final class ProcessMonitor {
    
    /// Check if any process named "vibe" is currently running
    static func isVibeRunning() -> Bool {
        let pipe = Pipe()
        let task = Process()
        
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-A", "-o", "comm="]
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Check for "vibe" process (could be "vibe" or "mistral-vibe" etc.)
                return output.localizedCaseInsensitiveContains("vibe")
            }
        } catch {
            // If ps fails, we're not running vibe
            return false
        }
        
        return false
    }
}
