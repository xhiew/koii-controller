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
        case "list_midi_outputs":   return listMidiOutputs()
        case "connect_device":      return try connectDevice(params.arguments)
        case "disconnect_device":   return disconnectDevice()
        case "transport_start":     return try transport(.start)
        case "transport_stop":      return try transport(.stop)
        case "transport_continue":  return try transport(.continue)
        case "play_pad":            return try await playPad(params.arguments)
        default:
            return CallTool.Result(
                content: [.text(text: "Unknown tool: \(params.name)", annotations: nil, _meta: nil)],
                isError: true
            )
        }
    }
}

// MARK: Connection handlers
private extension ToolHandler {
    private struct ListOutputsPayload: Encodable {
        let devices: [String]
    }
    
    static func listMidiOutputs() -> CallTool.Result {
        let devices = KOIIMIDIManager.shared.listDestinations()
        
        return CallTool.Result(
            content:[
                .text(
                    text: encodeJSON(ListOutputsPayload(devices: devices)),
                    annotations: nil,
                    _meta: nil
                )
            ]
        )
    }
    
    static func connectDevice(_ arguments: [String: Value]?) throws -> CallTool.Result {
        guard let args = arguments,
              case .string(let deviceName) = args["deviceName"] else {
            throw KOIIError.invalidParameter("deviceName is required")
        }
        
        try KOIIMIDIManager.shared.connect(deviceName: deviceName)
        
        return CallTool.Result(
            content:[
                .text(
                    text: "Connected to \"\(deviceName)\". (Note: this server is optimised for the EP-133 K.O. II)",
                    annotations: nil,
                    _meta: nil
                )
            ]
        )
    }
    
    static func disconnectDevice() -> CallTool.Result {
        KOIIMIDIManager.shared.disconnect()
        
        return CallTool.Result(
            content:[
                .text(
                    text: "The device has been disconnected.",
                    annotations: nil,
                    _meta: nil
                )
            ]
        )
    }
}

// MARK: Playback handlers
private extension ToolHandler {
    static func playPad(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let args = arguments,
              case .string(let groupStr) = args["group"],
              let padVal = args["pad"]?.intValue else {
            throw KOIIError.invalidParameter("group and pad are required")
        }
        
        guard let group = KOIIGroup(rawValue: groupStr.uppercased()) else {
            throw KOIIError.invalidParameter("Unknown group: \"\(groupStr)\". Use A, B, C, or D.")
        }
        
        let velocity = args["velocity"]?.intValue.flatMap { UInt7(exactly: $0) } ?? 80
        let bpm = args["bpm"]?.doubleValue
        let stepsPerBeat = args["steps_per_beat"]?.intValue ?? 4
        let durationSteps = args["duration_steps"]?.intValue ?? 1
        
        try KOIIMIDIManager.shared.send(event: KOIIDevice.noteOn(group: group, pad: padVal, velocity: velocity))
        
        if let bpm, bpm > 0 {
            let durationMs = (60_000.0 / bpm / Double(stepsPerBeat)) * Double(durationSteps)
            try await Task.sleep(nanoseconds: UInt64(durationMs * 1_000_000))
        }
        
        try KOIIMIDIManager.shared.send(event: KOIIDevice.noteOff(group: group, pad: padVal))
        
        let durationDesc: String
        if let bpm, bpm > 0 {
            let ms = (60_000.0 / bpm / Double(stepsPerBeat)) * Double(durationSteps)
            durationDesc = ", held \(durationSteps) step(s) @ \(Int(bpm)) BPM (\(Int(ms))ms)"
        } else {
            durationDesc = ""
        }
        
        return CallTool.Result(
            content:[
                .text(
                    text: "Played \(groupStr.uppercased())\(padVal) at velocity \(velocity)\(durationDesc).",
                    annotations: nil,
                    _meta: nil
                )
            ]
        )
    }
}

// MARK: Transport handlers
private enum TransportAction { case start, stop, `continue` }

private extension ToolHandler {
    static func transport(_ action: TransportAction) throws -> CallTool.Result {
        let event: MIDIEvent
        let label: String
        
        switch action {
        case .start:
            event = KOIIDevice.transportStart()
            label = "Start"
        case .stop:
            event = KOIIDevice.transportStop()
            label = "Stop"
        case .continue:
            event = KOIIDevice.transportContinue()
            label = "Continue"
        }
        
        try KOIIMIDIManager.shared.send(event: event)
        
        return CallTool.Result(
            content:[
                .text(
                    text: "Transport \(label) sent.",
                    annotations: nil,
                    _meta: nil
                )
            ]
        )
    }
}
