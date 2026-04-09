import Foundation

/// Watches a directory for file changes and notifies via AsyncStream.
struct FileWatcher: Sendable {
    let directory: String

    /// Start watching and yield changed file paths.
    func watch() -> AsyncStream<FileChange> {
        AsyncStream { continuation in
            // TODO: Use DispatchSource.makeFileSystemObjectSource on macOS
            //       Use inotify on Linux
            //       Yield FileChange events for each detected change
            continuation.onTermination = { _ in
                // Cleanup
            }
        }
    }
}

struct FileChange: Sendable {
    enum Kind: Sendable {
        case created
        case modified
        case deleted
    }

    let path: String
    let kind: Kind
}
