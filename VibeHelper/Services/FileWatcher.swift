import Foundation

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let path: String
    private let onChange: () -> Void

    init(path: String, onChange: @escaping () -> Void) {
        self.path = path
        self.onChange = onChange
    }

    func start() {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else {
            print("FileWatcher: Unable to open \(path): \(String(cString: strerror(errno)))")
            return
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            self?.onChange()
        }

        source?.setCancelHandler {
            close(fd)
        }

        source?.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }
}
