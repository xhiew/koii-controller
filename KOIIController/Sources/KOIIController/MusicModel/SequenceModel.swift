//
//  SequenceModel.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import SwiftMIDI

// MARK: Timing
struct SequenceTiming {
    let bpm: Double
    let stepsPerBeat: Int
    let beatsPerBar: Int
    
    var stepsPerBar: Int { stepsPerBeat * beatsPerBar }
    
    var stepDurationMs: Double { 60_000.0 / bpm / Double(stepsPerBeat) }
    
    var barDurationMs: Double { stepDurationMs * Double(stepsPerBar) }
    
    func offsetSteps(bar: Int, beat: Int, stepInBeat: Int = 1) -> Int {
        (bar - 1) * stepsPerBar + (beat - 1) * stepsPerBeat + (stepInBeat - 1)
    }
    
    func fireTime(offsetSteps: Int) -> Duration {
        .nanoseconds(Int(stepDurationMs * Double(offsetSteps) * 1_000_000))
    }
    
    func holdNanoseconds(durationSteps: Int) -> UInt64 {
        UInt64(stepDurationMs * Double(durationSteps) * 1_000_000)
    }
    
    /// Nanoseconds per beat — centralises the 60_000_000_000 constant.
    var beatNanoseconds: Int64 { Int64(60_000_000_000 / bpm) }
}

// MARK: SequenceStep
struct SequenceStep {
    let midiNote: UInt7
    let velocity: UInt7
    let offsetSteps: Int
    let durationSteps: Int
}
