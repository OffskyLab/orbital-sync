import ArgumentParser
import Foundation

struct DaemonCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "daemon",
        abstract: "Start the sync daemon"
    )

    @Option(name: .shortAndLong, help: "Port for NMT server")
    var port: Int = 9527

    @Option(name: .shortAndLong, help: "Path to sync directory")
    var syncDir: String?

    func run() async throws {
        let dir = syncDir ?? defaultSyncDirectory()
        print("Starting orbital-sync daemon on port \(port)")
        print("Sync directory: \(dir)")

        let daemon = SyncDaemon(port: port, syncDirectory: dir)
        try await daemon.start()
    }

    private func defaultSyncDirectory() -> String {
        if let custom = ProcessInfo.processInfo.environment["ORBITAL_HOME"] {
            return custom + "/shared"
        }
        return FileManager.default.homeDirectoryForCurrentUser.path + "/.orbital/shared"
    }
}
