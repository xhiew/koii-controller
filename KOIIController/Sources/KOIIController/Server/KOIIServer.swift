//
//  KOIIServer.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP

struct KOIIServer {
    static func createServer() async -> Server {
        let server = Server(
            name: "KOIIServer",
            version: "1.0.0",
            capabilities: Server.Capabilities(
                prompts: Server.Capabilities.Prompts(listChanged: false),
                resources: Server.Capabilities.Resources(subscribe: false, listChanged: false),
                tools: Server.Capabilities.Tools(listChanged: false)
            )
        )
        
        await ToolHandler.registerToolHandlers(on: server)
        
        await ResourceHandler.registerResourceHandlers(on: server)
        
        await PromptHandler.registerPromptHandlers(on: server)
        
        return server
    }
}
