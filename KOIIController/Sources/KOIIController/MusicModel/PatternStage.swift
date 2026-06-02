//
//  PatternStage.swift
//  KOIIController
//
//  Created by xhiew on 2/6/26.
//

import Foundation

actor PatternStage {
    static let shared = PatternStage()
    private init() {}
    
    private(set) var drumPattern: DrumPatternRequest?
    private(set) var keyMode: PlayKeyModeRequest?
    
    var isEmpty: Bool { drumPattern == nil && keyMode == nil }
    
    func stageDrum(_ req: DrumPatternRequest) { drumPattern = req }
    
    func stageKeyMode(_ req: PlayKeyModeRequest) { keyMode = req }
    
    func clear() { drumPattern = nil; keyMode = nil }
    
    var summary: String {
        var parts: [String] = []
        if let d = drumPattern {
            parts.append("drum: \(d.lines.count) instruments, \(d.stepCount) steps, \(d.totalBars) bars @ \(d.timing.bpm) BPM")
        }
        if let k = keyMode {
            parts.append("key_mode: \(k.steps.count) notes, \(k.root) \(k.scaleName) @ \(k.timing.bpm) BPM")
        }
        return parts.isEmpty ? "empty" : parts.joined(separator: "; ")
    }
}
