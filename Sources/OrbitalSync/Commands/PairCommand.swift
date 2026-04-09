import ArgumentParser

struct PairCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pair",
        abstract: "Pair with a remote peer"
    )

    @Argument(help: "Remote peer address (host:port)")
    var address: String

    func run() async throws {
        print("Pairing with \(address)...")
        // TODO: Send handshake via Unix domain socket to running daemon
    }
}
