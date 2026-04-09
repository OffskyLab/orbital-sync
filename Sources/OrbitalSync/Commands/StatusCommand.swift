import ArgumentParser

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show daemon and peer status"
    )

    func run() async throws {
        let client = ControlClient()
        do {
            let response = try client.send(ControlRequest(command: "status", args: nil))
            if response.ok {
                print(response.message)
                if let peers = response.data?["peers"], !peers.isEmpty {
                    print("Peers: \(peers)")
                }
            } else {
                print("Error: \(response.message)")
            }
        } catch SyncError.daemonNotRunning {
            print("Daemon is not running. Start it with: orbital-sync daemon")
        }
    }
}
