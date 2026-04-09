import ArgumentParser

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show daemon and peer status"
    )

    func run() async throws {
        // TODO: Query daemon via Unix domain socket
        print("Checking daemon status...")
    }
}
