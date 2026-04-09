import Foundation
import NMTP
import NIO
import Logging

/// Client for registering with and querying a rendezvous server.
actor RendezvousClient {
    let serverHost: String
    let serverPort: Int
    let logger = Logger(label: "orbital-sync.rv-client")

    private var client: NMTClient?
    private var heartbeatTask: Task<Void, Never>?

    init(host: String, port: Int) {
        self.serverHost = host
        self.serverPort = port
    }

    /// Connect to the rendezvous server and register this peer.
    /// Returns list of other peers in the same team.
    func register(peerID: String, peerName: String, teamID: String, host: String, port: Int) async throws -> [RVPeerEntry] {
        let address = try SocketAddress(ipAddress: serverHost, port: serverPort)
        let client = try await NMTClient.connect(to: address)
        self.client = client

        let body = RVRegisterBody(peerID: peerID, peerName: peerName, teamID: teamID, host: host, port: port)
        let argData = try JSONEncoder().encode(body)
        let callBody = CallBody(
            namespace: "orbital-sync",
            service: "rendezvous",
            method: SyncMethod.rvRegister,
            arguments: [EncodedArgument(key: "body", value: argData)]
        )
        let request = try Matter.make(type: .call, body: callBody)
        let response = try await client.request(matter: request)
        let reply = try response.decodeBody(CallReplyBody.self)

        guard let resultData = reply.result else { return [] }
        let registerReply = try JSONDecoder().decode(RVRegisterReplyBody.self, from: resultData)

        // Start heartbeat loop
        let hbPeerID = peerID
        let hbTeamID = teamID
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 25_000_000_000) // 25s
                await self.sendHeartbeat(peerID: hbPeerID, teamID: hbTeamID)
            }
        }

        logger.info("Registered with rendezvous server, \(registerReply.peers.count) peer(s) found")
        return registerReply.peers
    }

    func disconnect() async {
        heartbeatTask?.cancel()
        try? await client?.close()
        client = nil
    }

    private func sendHeartbeat(peerID: String, teamID: String) {
        guard let client else { return }
        let body = RVHeartbeatBody(peerID: peerID, teamID: teamID)
        guard let argData = try? JSONEncoder().encode(body) else { return }
        let callBody = CallBody(
            namespace: "orbital-sync",
            service: "rendezvous",
            method: SyncMethod.rvHeartbeat,
            arguments: [EncodedArgument(key: "body", value: argData)]
        )
        guard let matter = try? Matter.make(type: .call, body: callBody) else { return }
        client.fire(matter: matter)
    }
}
