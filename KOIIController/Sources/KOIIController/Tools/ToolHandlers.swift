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
        case "list_midi_outputs":
            return listMidiOutputs()
        case "connect_device":
            return try connectDevice(params.arguments)
        case "disconnect_device":
            return disconnectDevice()
        case "transport_start":
            return try transport(.start)
        case "transport_stop":
            return try transport(.stop)
        case "transport_continue":
            return try transport(.continue)
        case "play_pad":
            return try await playPad(params.arguments)
        case "play_key_mode":
            return try await playKeyMode(params.arguments)
        case "play_drum_pattern":
            return try await playDrumPattern(params.arguments)
        case "list_available_scales":
            return listAvailableScales()
        case "start_clock":
            return try startClock(params.arguments)
        case "stop_clock":
            return stopClock()
        case "fire_staged":
            return try await fireStagedPattern(params.arguments)
        case "clear_staged":
            return await clearStaged()
        default:
            return CallTool.Result(
                content: [.text(text: "Unknown tool: \(params.name)", annotations: nil, _meta: nil)],
                isError: true
            )
        }
    }
}

// MARK: Connection guard
private extension ToolHandler {
    static func requireConnected() throws {
        guard KOIIMIDIManager.shared.isConnected else {
            throw KOIIError.invalidParameter("No device connected. Call list_midi_outputs to find available devices, then connect_device.")
        }
    }
}

// MARK: Connection handlers
private extension ToolHandler {
    private struct ListOutputsPayload: Encodable {
        let devices: [String]
    }
    
    static func listMidiOutputs() -> CallTool.Result {
        .success(ListOutputsPayload(devices: KOIIMIDIManager.shared.listDestinations()))
    }
    
    static func connectDevice(_ arguments: [String: Value]?) throws -> CallTool.Result {
        guard let deviceName = arguments?["device_name"]?.stringValue else {
            throw KOIIError.invalidParameter("device_name is required")
        }
        try KOIIMIDIManager.shared.connect(deviceName: deviceName)
        return .message("Connected to \"\(deviceName)\". (Note: this server is optimised for the EP-133 K.O. II)")
    }
    
    static func disconnectDevice() -> CallTool.Result {
        KOIIMIDIManager.shared.disconnect()
        return .message("The device has been disconnected.")
    }
}

// MARK: MIDI fire primitives
// These functions accept pre-built request objects and send MIDI directly.
// Used by both play_* handlers (preview) and fire_staged (record sync).
private extension ToolHandler {
    static func fireDrum(_ req: DrumPatternRequest) async throws {
        let sequenceStart = ContinuousClock.now
        try await withThrowingTaskGroup(of: Void.self) { group in
            for step in 0..<req.stepCount {
                let hits: [(UInt7, UInt7)] = req.lines.compactMap { line in
                    guard step < line.hits.count, let velocity = line.hits[step] else { return nil }
                    return (line.midiNote, velocity)
                }
                guard !hits.isEmpty else { continue }
                let fireAt = sequenceStart + req.timing.fireTime(offsetSteps: step)
                let holdNs = req.timing.holdNanoseconds(durationSteps: 1)
                group.addTask {
                    try await Task.sleep(until: fireAt, clock: .continuous)
                    for (note, velocity) in hits {
                        try KOIIMIDIManager.shared.send(event: KOIIDevice.rawNoteOn(note: note, velocity: velocity))
                    }
                    try await Task.sleep(nanoseconds: holdNs)
                    for (note, _) in hits {
                        try KOIIMIDIManager.shared.send(event: KOIIDevice.rawNoteOff(note: note))
                    }
                }
            }
            try await group.waitForAll()
        }
    }
    
    static func fireKeyMode(_ req: PlayKeyModeRequest) async throws {
        let sequenceStart = ContinuousClock.now
        try await withThrowingTaskGroup(of: Void.self) { group in
            for step in req.steps {
                group.addTask {
                    let fireAt = sequenceStart + req.timing.fireTime(offsetSteps: step.offsetSteps)
                    try await Task.sleep(until: fireAt, clock: .continuous)
                    try KOIIMIDIManager.shared.send(event: KOIIDevice.rawNoteOn(note: step.midiNote, velocity: step.velocity))
                    try await Task.sleep(nanoseconds: req.timing.holdNanoseconds(durationSteps: step.durationSteps))
                    try KOIIMIDIManager.shared.send(event: KOIIDevice.rawNoteOff(note: step.midiNote))
                }
            }
            try await group.waitForAll()
        }
    }
}

// MARK: Playback handlers
private extension ToolHandler {
    static func playPad(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        try requireConnected()
        let req = try PlayPadRequest(from: arguments)
        
        try KOIIMIDIManager.shared.send(event: KOIIDevice.noteOn(group: req.group, pad: req.pad, velocity: req.velocity))
        try await Task.sleep(nanoseconds: req.timing.holdNanoseconds(durationSteps: req.durationSteps))
        try KOIIMIDIManager.shared.send(event: KOIIDevice.noteOff(group: req.group, pad: req.pad))
        
        return .success(
            PlayPadResponse(
                status: "OK",
                group: req.group.rawValue,
                pad: req.pad,
                velocity: Int(req.velocity),
                durationSteps: req.durationSteps,
                bpm: req.timing.bpm,
                stepsPerBeat: req.timing.stepsPerBeat,
                stepMs: req.timing.stepDurationMs,
                totalDurationMs: req.timing.stepDurationMs * Double(req.durationSteps)
            )
        )
    }
    
    static func listAvailableScales() -> CallTool.Result {
        .success(KOIIScaleLibrary.descriptions)
    }
    
    static func playKeyMode(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        try requireConnected()
        let req = try PlayKeyModeRequest(from: arguments)
        try await fireKeyMode(req)
        await PatternStage.shared.stage(.keyMode(req))
        
        return .success(
            PlayKeyModeResponse(
                status: "OK",
                notesPlayed: req.steps.count,
                root: req.root,
                scaleName: req.scaleName,
                defaultOctave: req.defaultOctave,
                beatsPerBar: req.timing.beatsPerBar,
                stepsPerBeat: req.timing.stepsPerBeat,
                bpm: req.timing.bpm,
                stepMs: req.timing.stepDurationMs,
                totalDurationMs: req.totalDurationMs
            )
        )
    }
    
    static func playDrumPattern(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        try requireConnected()
        let req = try DrumPatternRequest(from: arguments)
        try await fireDrum(req)
        await PatternStage.shared.stage(.drum(req))
        
        return .success(
            DrumPatternResponse(
                status: "OK",
                instrumentsPlayed: req.lines.count,
                steps: req.stepCount,
                bars: req.totalBars,
                beatsPerBar: req.timing.beatsPerBar,
                bpm: req.timing.bpm,
                stepMs: req.timing.stepDurationMs,
                totalDurationMs: req.totalDurationMs
            )
        )
    }
}

// MARK: Transport handlers
private enum TransportAction { case start, stop, `continue` }

private extension ToolHandler {
    static func transport(_ action: TransportAction) throws -> CallTool.Result {
        try requireConnected()
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
        return .message("Transport \(label) sent.")
    }
}

// MARK: Clock handlers
private extension ToolHandler {
    static func startClock(_ arguments: [String: Value]?) throws -> CallTool.Result {
        try requireConnected()
        guard let args = arguments,
              let bpm = args["bpm"]?.intValue,
              bpm > 0 else {
            throw KOIIError.invalidParameter("bpm is required and must be > 0")
        }
        try KOIIMIDIManager.shared.startClock(bpm: Double(bpm))
        let intervalMs = 60_000.0 / (Double(bpm) * 24)
        return .message("MIDI Clock started at \(bpm) BPM (interval: \(String(format: "%.2f", intervalMs)) ms, 24 PPQ).")
    }
    
    static func stopClock() -> CallTool.Result {
        KOIIMIDIManager.shared.stopClock()
        return .message("MIDI Clock stopped.")
    }
}

// MARK: Pattern staging handlers
private extension ToolHandler {
    static func fireStagedPattern(_ arguments: [String: Value]?) async throws -> CallTool.Result {
        try requireConnected()
        
        let stage = PatternStage.shared
        guard let staged = await stage.staged else {
            throw KOIIError.invalidParameter("Nothing staged. Call play_drum_pattern or play_key_mode first.")
        }
        
        let countdownBeats = arguments?["countdown_beats"]?.intValue ?? 4
        
        if countdownBeats > 0 {
            // Send MIDI Start to trigger KO-II's count-in in sync with our own countdown
            try KOIIMIDIManager.shared.send(event: KOIIDevice.transportStart())
            // Prefer clock BPM so the countdown matches the external tempo source
            let bpmForCountdown = KOIIMIDIManager.shared.clockBpm ?? staged.timing.bpm
            let beatNs = Int64(60_000_000_000 / bpmForCountdown)
            let fireAt = ContinuousClock.now + .nanoseconds(beatNs * Int64(countdownBeats))
            try await Task.sleep(until: fireAt, clock: .continuous)
        }
        
        switch staged {
        case .drum(let req): try await fireDrum(req)
        case .keyMode(let req): try await fireKeyMode(req)
        }
        
        let summary = await stage.summary
        
        return .success(
            FireStagedResponse(
                status: "OK",
                startSent: countdownBeats > 0,
                countdownBeats: countdownBeats,
                pattern: summary,
                totalDurationMs: staged.totalDurationMs
            )
        )
    }
    
    static func clearStaged() async -> CallTool.Result {
        let cleared = await PatternStage.shared.clearAndSummarize()
        
        return .success(
            ClearStagedResponse(
                status: "OK",
                cleared: cleared == "empty" ? "nothing" : cleared
            )
        )
    }
}

