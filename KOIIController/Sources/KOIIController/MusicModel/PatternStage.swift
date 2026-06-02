//
//  PatternStage.swift
//  KOIIController
//
//  Created by xhiew on 2/6/26.
//

import Foundation

enum StagedPattern {
    case drum(DrumPatternRequest)
    case keyMode(PlayKeyModeRequest)
    
    var timing: SequenceTiming {
        switch self {
        case .drum(let r): r.timing
        case .keyMode(let r): r.timing
        }
    }
    
    var totalDurationMs: Double {
        switch self {
        case .drum(let r): r.totalDurationMs
        case .keyMode(let r): r.totalDurationMs
        }
    }
}

actor PatternStage {
    static let shared = PatternStage()
    private init() {}
    
    private(set) var staged: StagedPattern?
    
    var isEmpty: Bool { staged == nil }
    
    func stage(_ pattern: StagedPattern) { staged = pattern }
    
    func clear() { staged = nil }
    
    // Captures summary then clears atomically (single actor turn — no race window).
    func clearAndSummarize() -> String {
        let s = summary
        staged = nil
        return s
    }
    
    var summary: String {
        switch staged {
        case .drum(let d):
            return "drum: \(d.lines.count) instruments, \(d.stepCount) steps, \(d.totalBars) bars @ \(Int(d.timing.bpm)) BPM"
        case .keyMode(let k):
            return "key_mode: \(k.steps.count) notes, \(k.root) \(k.scaleName) @ \(Int(k.timing.bpm)) BPM"
        case nil:
            return "empty"
        }
    }
}
