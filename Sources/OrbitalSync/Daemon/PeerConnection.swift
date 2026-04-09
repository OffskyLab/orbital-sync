import Foundation
import NMTP

/// Represents a connected peer in the mesh.
struct PeerConnection: Sendable {
    let peerID: String
    let peerName: String
    let address: String
    let port: Int
    let client: NMTClient
}
