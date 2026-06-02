//
//  PlayRequests.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP
import SwiftMIDI

struct PlayPadRequest {
    let group: KOIIGroup
    let pad: Int
    let velocity: UInt7
    let timing: SequenceTiming
    let durationSteps: Int
    
    init(from arguments: [String: Value]?) throws {
        guard let args = arguments,
              case .string(let groupStr) = args["group"],
              let padVal = args["pad"]?.intValue else {
            throw KOIIError.invalidParameter("group and pad are required")
        }
        
        guard let group = KOIIGroup(rawValue: groupStr.uppercased()) else {
            throw KOIIError.invalidParameter("Unknown group: \"\(groupStr)\". Use A, B, C, or D.")
        }
        
        guard let bpmInt = args["bpm"]?.intValue, bpmInt > 0 else {
            throw KOIIError.invalidParameter("bpm is required and must be > 0")
        }
        
        self.group = group
        self.pad = padVal
        self.velocity = args["velocity"]?.intValue.flatMap { UInt7(exactly: $0) } ?? 80
        self.durationSteps = args["duration_steps"]?.intValue ?? 1
        self.timing = SequenceTiming(bpm: Double(bpmInt), stepsPerBeat: args["steps_per_beat"]?.intValue ?? 4, beatsPerBar: 4)
    }
}

struct PlayKeyModeRequest {
    let timing: SequenceTiming
    let steps: [SequenceStep]
    let root: String
    let scaleName: String
    let defaultOctave: Int
    
    init(from arguments: [String: Value]?) throws {
        guard let args = arguments,
              let bpmInt = args["bpm"]?.intValue, bpmInt > 0,
              case .array(let stepsArr) = args["steps"] else {
            throw KOIIError.invalidParameter("bpm and steps are required")
        }
        let bpmVal = Double(bpmInt)
        
        guard !stepsArr.isEmpty else { throw KOIIError.invalidParameter("steps must contain at least one note") }
        
        let beatsPerBar = args["beats_per_bar"]?.intValue ?? 4
        let stepsPerBeat = args["steps_per_beat"]?.intValue ?? 4
        
        guard beatsPerBar >= 1 else { throw KOIIError.invalidParameter("beats_per_bar must be >= 1") }
        guard stepsPerBeat >= 1 else { throw KOIIError.invalidParameter("steps_per_beat must be >= 1") }
        
        let rootName = args["root"]?.stringValue ?? "C"
        let scaleName = args["scale_name"]?.stringValue ?? "major"
        let defaultOctave = args["octave"]?.intValue ?? 4
        
        guard (0...9).contains(defaultOctave) else {
            throw KOIIError.invalidParameter("octave must be in 0...9, got \(defaultOctave)")
        }
        
        let timing = SequenceTiming(bpm: bpmVal, stepsPerBeat: stepsPerBeat, beatsPerBar: beatsPerBar)
        var steps: [SequenceStep] = []
        
        for (i, item) in stepsArr.enumerated() {
            guard case .object(let step) = item,
                  let degree = step["degree"]?.intValue,
                  let bar = step["bar"]?.intValue,
                  let beat = step["beat"]?.intValue else {
                throw KOIIError.invalidParameter("Step \(i): degree, bar, and beat are required")
            }
            
            guard bar >= 1 else { throw KOIIError.invalidParameter("Step \(i): bar must be >= 1, got \(bar)") }
            guard beat >= 1, beat <= beatsPerBar else {
                throw KOIIError.invalidParameter("Step \(i): beat must be in 1...\(beatsPerBar), got \(beat)")
            }
            
            let stepInBeat = step["step_in_beat"]?.intValue ?? 1
            guard stepInBeat >= 1, stepInBeat <= stepsPerBeat else {
                throw KOIIError.invalidParameter("Step \(i): step_in_beat must be in 1...\(stepsPerBeat), got \(stepInBeat)")
            }
            
            let effectiveOctave: Int
            if let stepOctave = step["octave"]?.intValue {
                guard (0...9).contains(stepOctave) else {
                    throw KOIIError.invalidParameter("Step \(i): octave must be in 0...9, got \(stepOctave)")
                }
                effectiveOctave = stepOctave
            } else {
                effectiveOctave = defaultOctave
            }
            
            let velocityRaw = step["velocity"]?.intValue ?? 80
            guard let velocity = UInt7(exactly: velocityRaw) else {
                throw KOIIError.invalidParameter("Step \(i): velocity must be in 0...127, got \(velocityRaw)")
            }
            
            let durationSteps = step["duration_steps"]?.intValue ?? 1
            guard durationSteps >= 1 else {
                throw KOIIError.invalidParameter("Step \(i): duration_steps must be >= 1, got \(durationSteps)")
            }
            
            let midiNote: UInt7
            do {
                midiNote = try KOIIScaleLibrary.midiNote(root: rootName, scaleName: scaleName, degree: degree, octave: effectiveOctave)
            } catch {
                throw KOIIError.invalidParameter("Step \(i): \(error.localizedDescription)")
            }
            
            let offsetSteps = timing.offsetSteps(bar: bar, beat: beat, stepInBeat: stepInBeat)
            steps.append(SequenceStep(midiNote: midiNote, velocity: velocity, offsetSteps: offsetSteps, durationSteps: durationSteps))
        }
        
        self.timing = timing
        self.steps = steps
        self.root = rootName
        self.scaleName = scaleName
        self.defaultOctave = defaultOctave
    }
    
    var totalDurationMs: Double {
        let maxEnd = steps.map { $0.offsetSteps + $0.durationSteps }.max() ?? 0
        return timing.stepDurationMs * Double(maxEnd)
    }
}
