import Foundation
import NMTP
import Logging

/// Core daemon that manages NMT server, peer connections, and file watching.
actor SyncDaemon {
    let port: Int
    let syncDirectory: String
    let logger = Logger(label: "orbital-sync")

    private var server: NMTServer?
    private var peers: [PeerConnection] = []

    init(port: Int, syncDirectory: String) {
        self.port = port
        self.syncDirectory = syncDirectory
    }

    func start() async throws {
        logger.info("Starting sync daemon", metadata: [
            "port": "\(port)",
            "syncDir": "\(syncDirectory)",
        ])

        // TODO: Phase 1 implementation
        // 1. Start NMTServer on configured port
        // 2. Start Unix domain socket listener for CLI commands
        // 3. Start file watcher on syncDirectory
        // 4. Connect to configured peers

        // Keep daemon alive
        try await withCheckedThrowingContinuation { (_: CheckedContinuation<Void, Error>) in
            // Daemon runs until terminated
        }
    }
}
