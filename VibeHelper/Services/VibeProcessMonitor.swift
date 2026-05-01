import Foundation

@MainActor
final class VibeProcessMonitor: ObservableObject {
    @Published private(set) var isRunning = false

    private var timer: Timer?

    init() {
        Task { @MainActor in
            await start()
        }
    }

    deinit {
        // Timer invalidation is thread-safe and doesn't need @MainActor
        timer?.invalidate()
        timer = nil
    }

    private func start() async {
        await refresh()
        startTimer()
    }

    private func startTimer() {
        // Invalidate any existing timer first
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    private func refresh() async {
        async let vibe = pgrep("vibe")
        async let python = pgrep("python")
        let (vibeResult, pythonResult) = await (vibe, python)
        isRunning = vibeResult || pythonResult
    }

    private func pgrep(_ pattern: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let pipe = Pipe()
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
            task.arguments = [pattern]
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice

            do {
                try task.run()
            } catch {
                continuation.resume(returning: false)
                return
            }

            task.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
                    continuation.resume(returning: false)
                    return
                }

                let ownPid = Int32(ProcessInfo.processInfo.processIdentifier)
                let found = output.split(separator: "\n").contains { line in
                    Int32(line.trimmingCharacters(in: .whitespaces)) != ownPid
                }
                continuation.resume(returning: found)
            }
        }
    }
}
