//
//  ToolDefinitions.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP

struct ToolDefinition {
    static let all: [Tool] = [
        Tool(
            name: "list_midi_outputs",
            description: "Lists all available MIDI output ports on the system. Call this first to find the KO-II device name before connecting.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "connect_device",
            description: "Connects to a MIDI output port by name. This server is designed for the Teenage Engineering EP-133 K.O. II — select that device if available.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "deviceName": .object([
                        "type": .string("string"),
                        "description": .string("Exact MIDI port name as returned by list_midi_outputs")
                    ])
                ]),
                "required": .array([.string("deviceName")])
            ])
        ),
        Tool(
            name: "disconnect_device",
            description: "Disconnects from the currently connected MIDI device.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([:])
            ])
        )
    ]
}
