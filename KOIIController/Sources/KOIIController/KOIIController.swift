import ArgumentParser
import Foundation
import MCP

@main
struct KOIIController: AsyncParsableCommand {
    func run() async throws {
        try KOIIMIDIManager.shared.start()
        let server = await KOIIServer.createServer()
        let transport = StdioTransport()
        try await server.start(transport: transport)
        try await Task.sleep(nanoseconds: .max)
    }
}
