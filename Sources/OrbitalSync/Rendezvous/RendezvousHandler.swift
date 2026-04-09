import Foundation
import NMTP
import NIO
import Logging

/// Handles incoming NMT Matter for the rendezvous server.
struct RendezvousHandler: NMTHandler {
    let server: RendezvousServer
    let logger = Logger(label: "orbital-sync.rendezvous.handler")

    func handle(matter: Matter, channel: Channel) async throws -> Matter? {
        guard matter.type == .call else { return nil }
        let body = try matter.decodeBody(CallBody.self)

        switch body.method {
        case SyncMethod.rvRegister:
            return try await handleRegister(matter: matter, body: body, channel: channel)
        case SyncMethod.rvHeartbeat:
            return try await handleHeartbeat(matter: matter, body: body)
        case SyncMethod.rvUnregister:
            return try await handleUnregister(matter: matter, body: body)
        default:
            return try matter.reply(body: CallReplyBody(result: nil, error: "Unknown method: \(body.method)"))
        }
    }

    private func handleRegister(matter: Matter, body: CallBody, channel: Channel) async throws -> Matter? {
        let request = try decodeArgument(RVRegisterBody.self, from: body)
        let remoteHost = channel.remoteAddress?.ipAddress
        let reply = await server.register(request, remoteAddress: remoteHost)
        let data = try JSONEncoder().encode(reply)
        return try matter.reply(body: CallReplyBody(result: data, error: nil))
    }

    private func handleHeartbeat(matter: Matter, body: CallBody) async throws -> Matter? {
        let request = try decodeArgument(RVHeartbeatBody.self, from: body)
        let reply = await server.heartbeat(request)
        let data = try JSONEncoder().encode(reply)
        return try matter.reply(body: CallReplyBody(result: data, error: nil))
    }

    private func handleUnregister(matter: Matter, body: CallBody) async throws -> Matter? {
        let request = try decodeArgument(RVRegisterBody.self, from: body)
        await server.unregister(peerID: request.peerID, teamID: request.teamID)
        let data = try JSONEncoder().encode(RVHeartbeatReplyBody(ok: true))
        return try matter.reply(body: CallReplyBody(result: data, error: nil))
    }

    private func decodeArgument<T: Decodable>(_ type: T.Type, from body: CallBody) throws -> T {
        guard let arg = body.arguments.first else { throw SyncError.missingArgument }
        return try JSONDecoder().decode(type, from: arg.value)
    }
}
