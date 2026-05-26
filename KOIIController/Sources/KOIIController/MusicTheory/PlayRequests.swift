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
        
        guard let bpm = args["bpm"]?.doubleValue, bpm > 0 else {
            throw KOIIError.invalidParameter("bpm is required and must be > 0")
        }
        
        self.group = group
        self.pad = padVal
        self.velocity = args["velocity"]?.intValue.flatMap { UInt7(exactly: $0) } ?? 80
        self.durationSteps = args["duration_steps"]?.intValue ?? 1
        self.timing = SequenceTiming(bpm: bpm, stepsPerBeat: args["steps_per_beat"]?.intValue ?? 4)
    }
}

struct PlaySequenceRequest {
    let timing: SequenceTiming
    let steps: [SequenceStep]
    
    init(from arguments: [String: Value]?) throws {
        guard let args = arguments,
              let bpmVal = args["bpm"]?.doubleValue, bpmVal > 0,
              case .array(let stepsArr) = args["steps"] else {
            throw KOIIError.invalidParameter("bpm and steps are required")
        }
        
        var steps: [SequenceStep] = []
        for (i, item) in stepsArr.enumerated() {
            guard case .object(let step) = item,
                  case .string(let groupStr) = step["group"],
                  let group = KOIIGroup(rawValue: groupStr.uppercased()),
                  let pad = step["pad"]?.intValue,
                  let offsetSteps = step["offset_steps"]?.intValue else {
                throw KOIIError.invalidParameter("Step \(i): group, pad, and offset_steps are required")
            }
            
            let velocity = step["velocity"]?.intValue.flatMap { UInt7(exactly: $0) } ?? 80
            let durationSteps = step["duration_steps"]?.intValue ?? 1
            steps.append(SequenceStep(group: group, pad: pad, velocity: velocity, offsetSteps: offsetSteps, durationSteps: durationSteps))
        }
        
        self.timing = SequenceTiming(bpm: bpmVal, stepsPerBeat: args["steps_per_beat"]?.intValue ?? 4)
        self.steps = steps
    }
}
