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

    // MARK: - Dispatch

    private static func dispatch(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        switch params.name {
        case "list_midi_outputs":    return listMidiOutputs()
        case "connect_device":       return try connectDevice(params.arguments)
        case "disconnect_device":    return disconnectDevice()
        case "assign_group_channel": return try assignGroupChannel(params.arguments)
        case "play_note":            return try await playNote(params.arguments)
        case "play_notes":           return try await playNotes(params.arguments)
        default:
            return CallTool.Result(
                content: [.text(text: "Unknown tool: \(params.name)", annotations: nil, _meta: nil)],
                isError: true
            )
        }
    }

    // MARK: - list_midi_outputs

    private static func listMidiOutputs() -> CallTool.Result {
        let devices = KOIIMIDIManager.shared.listDestinations()
        return CallTool.Result(content: [
            .text(text: encodeJSON(ListOutputsPayload(devices: devices)), annotations: nil, _meta: nil)
        ])
    }

    // MARK: - connect_device

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

    // MARK: - disconnect_device

    private static func disconnectDevice() -> CallTool.Result {
        KOIIMIDIManager.shared.disconnect()
        KOIIChannelMap.shared.reset()
        return CallTool.Result(content: [
            .text(text: "Disconnected. Channel map reset to defaults.", annotations: nil, _meta: nil)
        ])
    }

    // MARK: - assign_group_channel

    private static func assignGroupChannel(_ arguments: [String: Value]?) throws -> CallTool.Result {
        guard let args = arguments,
              case .string(let groupStr) = args["group"],
              let group = KOIIGroup(rawValue: groupStr.uppercased()),
              let channel = args["channel"]?.asInt else {
            throw KOIIError.invalidParameter("group (A–D) and channel (1–16) are required")
        }
        let clamped = min(16, max(1, channel))
        KOIIChannelMap.shared.assign(channel: clamped, to: group)
        return CallTool.Result(content: [
            .text(text: "Group \(group.rawValue) → MIDI channel \(clamped)", annotations: nil, _meta: nil)
        ])
    }

    // MARK: - play_note

    private static func playNote(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let args = arguments else {
            throw KOIIError.invalidParameter("Arguments required")
        }
        let note = try NoteInput(from: args)
        let velocity = UInt7(min(127, max(0, note.velocity)))
        let channel  = UInt4(note.effectiveChannel - 1)

        try KOIIMIDIManager.shared.send(event:
            try KOIIDevice.noteOn(group: note.group, pad: note.pad, velocity: velocity, channel: channel)
        )
        try await Task.sleep(for: .milliseconds(note.durationMs))
        try KOIIMIDIManager.shared.send(event:
            try KOIIDevice.noteOff(group: note.group, pad: note.pad, channel: channel)
        )

        return CallTool.Result(content: [
            .text(
                text: "Played \(note.group.rawValue)\(note.pad) — velocity \(note.velocity), ch\(note.effectiveChannel), \(note.durationMs)ms",
                annotations: nil, _meta: nil
            )
        ])
    }

    // MARK: - play_notes

    private static func playNotes(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let args = arguments,
              let notesValue = args["notes"],
              case .array(let noteValues) = notesValue,
              !noteValues.isEmpty else {
            throw KOIIError.invalidParameter("notes must be a non-empty array")
        }

        let notes = try noteValues.map { noteValue -> NoteInput in
            guard case .object(let noteObj) = noteValue else {
                throw KOIIError.invalidParameter("Each note must be an object")
            }
            return try NoteInput(from: noteObj)
        }

        // Fire all noteOns simultaneously
        let onEvents = try notes.map { note -> MIDIEvent in
            try KOIIDevice.noteOn(
                group: note.group,
                pad: note.pad,
                velocity: UInt7(min(127, max(0, note.velocity))),
                channel: UInt4(note.effectiveChannel - 1)
            )
        }
        try KOIIMIDIManager.shared.send(events: onEvents)

        // Each noteOff fires after its own durationMs (precise per-note timing)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for note in notes {
                group.addTask {
                    try await Task.sleep(for: .milliseconds(note.durationMs))
                    try KOIIMIDIManager.shared.send(event:
                        try KOIIDevice.noteOff(
                            group: note.group,
                            pad: note.pad,
                            channel: UInt4(note.effectiveChannel - 1)
                        )
                    )
                }
            }
            try await group.waitForAll()
        }

        let groupList   = Set(notes.map { $0.group.rawValue }).sorted().joined(separator: ", ")
        let channelList = Set(notes.map { $0.effectiveChannel }).sorted().map(String.init).joined(separator: ", ")
        return CallTool.Result(content: [
            .text(
                text: "Played \(notes.count) note(s) — groups: \(groupList), channels: \(channelList)",
                annotations: nil, _meta: nil
            )
        ])
    }
}

// MARK: - NoteInput

private struct NoteInput: Sendable {
    let group: KOIIGroup
    let pad: Int
    let velocity: Int    // 0–127
    let durationMs: Int
    let channelOverride: Int?  // nil = use KOIIChannelMap, 1–16 = explicit override

    var effectiveChannel: Int {
        channelOverride ?? KOIIChannelMap.shared.channel(for: group)
    }

    init(from obj: [String: Value]) throws {
        guard case .string(let groupStr) = obj["group"],
              let group = KOIIGroup(rawValue: groupStr.uppercased()) else {
            throw KOIIError.invalidParameter("group must be A, B, C, or D")
        }
        guard let pad = obj["pad"]?.asInt, (1...12).contains(pad) else {
            throw KOIIError.invalidParameter("pad must be 1–12")
        }
        self.group           = group
        self.pad             = pad
        self.velocity        = min(127, max(0, obj["velocity"]?.asInt  ?? 80))
        self.durationMs      = max(1,           obj["durationMs"]?.asInt ?? 200)
        self.channelOverride = obj["channel"]?.asInt.map { min(16, max(1, $0)) }
    }
}

// MARK: - Value helpers

private extension Value {
    var asInt: Int? {
        switch self {
        case .int(let i):    return i
        case .double(let d): return Int(exactly: d)
        default:             return nil
        }
    }
}

// MARK: - Encodable payloads

private struct ListOutputsPayload: Encodable {
    let devices: [String]
}
