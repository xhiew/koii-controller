//
//  ToolResponseModels.swift
//  KOIIController
//
//  Created by xhiew on 2/6/26.
//

import Foundation

// MARK: Response types
struct PlayPadResponse: Encodable {
    let status: String
    let group: String
    let pad: Int
    let velocity: Int
    let durationSteps: Int
    let bpm: Double
    let stepsPerBeat: Int
    let stepMs: Double
    let totalDurationMs: Double
}

struct PlayKeyModeResponse: Encodable {
    let status: String
    let notesPlayed: Int
    let root: String
    let scaleName: String
    let defaultOctave: Int
    let beatsPerBar: Int
    let stepsPerBeat: Int
    let bpm: Double
    let stepMs: Double
    let totalDurationMs: Double
}

struct DrumPatternResponse: Encodable {
    let status: String
    let instrumentsPlayed: Int
    let steps: Int
    let bars: Int
    let beatsPerBar: Int
    let bpm: Double
    let stepMs: Double
    let totalDurationMs: Double
}

struct FireStagedResponse: Encodable {
    let status: String
    let clockSynced: Bool
    let countdownBeats: Int
    let pattern: String
    let totalDurationMs: Double
}

struct ClearStagedResponse: Encodable {
    let status: String
    let cleared: String
}
