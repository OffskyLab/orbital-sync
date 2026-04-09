import Foundation
import NMTP
import NIO
import Logging

/// Lightweight coordination server for cross-network peer discovery.
/// Does NOT relay data — only exchanges peer connection info.
actor RendezvousServer {
    let port: Int
    let logger = Logger(label: "orbital-sync.rendezvous")

    private var server: NMTServer?
    /// teamID → [peerID: registration]
    private var registry: [String: [String: PeerRegistration]] = [:]

    struct PeerRegistration {
        let peerID: String
        let peerName: String
        let host: String
        let port: Int
        let lastSeen: Date
    }

    init(port: Int) {
        self.port = port
    }

    func start() async throws {
        let handler = RendezvousHandler(server: self)
        let address = try SocketAddress(ipAddress: "0.0.0.0", port: port)
        server = try await NMTServer.bind(on: address, handler: handler)
        logger.info("Rendezvous server listening on port \(port)")

        // Start cleanup task — remove stale registrations every 30s
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await self.cleanupStale()
            }
        }

        try await server?.listen()
    }

    func stop() async throws {
        try await server?.stop()
    }

    // MARK: - Registry operations

    func register(_ body: RVRegisterBody, remoteAddress: String?) -> RVRegisterReplyBody {
        let host = body.host.isEmpty ? (remoteAddress ?? body.host) : body.host
        let reg = PeerRegistration(
            peerID: body.peerID,
            peerName: body.peerName,
            host: host,
            port: body.port,
            lastSeen: Date()
        )

        var teamPeers = registry[body.teamID] ?? [:]
        teamPeers[body.peerID] = reg
        registry[body.teamID] = teamPeers

        logger.info("Registered \(body.peerName) (\(body.peerID)) for team \(body.teamID) at \(host):\(body.port)")

        // Return all OTHER peers in the same team
        let otherPeers = teamPeers.values
            .filter { $0.peerID != body.peerID }
            .map { RVPeerEntry(peerID: $0.peerID, peerName: $0.peerName, host: $0.host, port: $0.port) }

        return RVRegisterReplyBody(peers: otherPeers)
    }

    func heartbeat(_ body: RVHeartbeatBody) -> RVHeartbeatReplyBody {
        if var teamPeers = registry[body.teamID],
           var reg = teamPeers[body.peerID] {
            reg = PeerRegistration(
                peerID: reg.peerID, peerName: reg.peerName,
                host: reg.host, port: reg.port, lastSeen: Date()
            )
            teamPeers[body.peerID] = reg
            registry[body.teamID] = teamPeers
        }
        return RVHeartbeatReplyBody(ok: true)
    }

    func unregister(peerID: String, teamID: String) {
        registry[teamID]?.removeValue(forKey: peerID)
        logger.info("Unregistered \(peerID) from team \(teamID)")
    }

    private func cleanupStale() {
        let staleThreshold: TimeInterval = 90 // 3 missed heartbeats (30s each)
        let now = Date()
        for (teamID, peers) in registry {
            let alive = peers.filter { now.timeIntervalSince($0.value.lastSeen) < staleThreshold }
            let removed = peers.count - alive.count
            if removed > 0 {
                logger.info("Cleaned up \(removed) stale peer(s) from team \(teamID)")
            }
            registry[teamID] = alive.isEmpty ? nil : alive
        }
    }
}
