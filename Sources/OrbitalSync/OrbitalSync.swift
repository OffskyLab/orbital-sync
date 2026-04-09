import ArgumentParser

@main
struct OrbitalSyncCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "orbital-sync",
        abstract: "P2P real-time sync daemon for Orbital",
        version: "0.1.0",
        subcommands: [
            DaemonCommand.self,
            PairCommand.self,
            StatusCommand.self,
            TeamCommand.self,
        ]
    )
}
