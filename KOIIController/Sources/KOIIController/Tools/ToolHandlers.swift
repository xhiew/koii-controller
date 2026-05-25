//
//  ToolHandlers.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP
import SwiftMIDI

struct ToolHandler {
    static func registerToolHandlers(on server: Server) async {
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: ToolDefinition.all)
        }

        await server.withMethodHandler(CallTool.self) { params in
            do {
                return try await dispatch(params)
            } catch {
                return CallTool.Result(
                    content: [.text(text: error.localizedDescription, annotations: nil, _meta: nil)],
                    isError: true
                )
            }
        }
    }

    // MARK: Dispatch
    private static func dispatch(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        switch params.name {
        case "list_midi_outputs":    return listMidiOutputs()
        case "connect_device":       return try connectDevice(params.arguments)
        case "disconnect_device":    return disconnectDevice()
        default:
            return CallTool.Result(
                content: [.text(text: "Unknown tool: \(params.name)", annotations: nil, _meta: nil)],
                isError: true
            )
        }
    }

    // MARK: list_midi_outputs
    private static func listMidiOutputs() -> CallTool.Result {
        let devices = KOIIMIDIManager.shared.listDestinations()
        return CallTool.Result(content: [
            .text(text: encodeJSON(ListOutputsPayload(devices: devices)), annotations: nil, _meta: nil)
        ])
    }

    // MARK: connect_device
    private static func connectDevice(_ arguments: [String: Value]?) throws -> CallTool.Result {
        guard let args = arguments,
              case .string(let deviceName) = args["deviceName"] else {
            throw KOIIError.invalidParameter("deviceName is required")
        }
        try KOIIMIDIManager.shared.connect(deviceName: deviceName)
        let isKOII = deviceName.contains("K.O") || deviceName.contains("EP-133")
        let note = isKOII ? "" : " (Note: this server is optimised for the EP-133 K.O. II)"
        return CallTool.Result(content: [
            .text(text: "Connected to \"\(deviceName)\"\(note)", annotations: nil, _meta: nil)
        ])
    }

    // MARK: disconnect_device
    private static func disconnectDevice() -> CallTool.Result {
        KOIIMIDIManager.shared.disconnect()
        return CallTool.Result(content: [.text(text: "Disconnected. Channel map reset to defaults.", annotations: nil, _meta: nil)])
    }
}

// MARK: ListOutputsPayload
private struct ListOutputsPayload: Encodable {
    let devices: [String]
}
