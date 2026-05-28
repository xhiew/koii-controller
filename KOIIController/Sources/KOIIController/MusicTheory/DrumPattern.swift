//
//  DrumPattern.swift
//  KOIIController
//
//  Created by xhiew on 26/5/26.
//

import Foundation
import MCP
import SwiftMIDI

// MARK: DrumPatternLine
struct DrumPatternLine: Sendable {
    let midiNote: UInt7
    
    /// Velocity per step; nil = rest.
    let hits: [UInt7?]
}

// MARK: DrumPatternRequest
struct DrumPatternRequest: Sendable {
    let lines: [DrumPatternLine]
    let timing: SequenceTiming
    let stepCount: Int
    let totalBars: Int
    
    init(from args: [String: Value]?) throws {
        guard let args else { throw KOIIError.invalidParameter("arguments required") }
        guard let bpm = args["bpm"]?.doubleValue, bpm > 0 else { throw KOIIError.invalidParameter("bpm is required and must be > 0") }
        guard case .string(let text) = args["pattern"] else { throw KOIIError.invalidParameter("pattern is required (multi-line string)") }
        
        let beatsPerBar = args["beats_per_bar"]?.intValue ?? 4
        timing = SequenceTiming(bpm: bpm, stepsPerBeat: args["steps_per_beat"]?.intValue ?? 4, beatsPerBar: beatsPerBar)
        lines = try Self.parseLines(text)
        
        guard !lines.isEmpty else { throw KOIIError.invalidParameter("No valid pattern lines found — check instrument references") }
        
        stepCount = lines.map { $0.hits.count }.max() ?? 0
        totalBars = stepCount > 0 ? (stepCount + timing.stepsPerBar - 1) / timing.stepsPerBar : 0
    }
}

// MARK: Parsing
private extension DrumPatternRequest {
    static func parseLines(_ text: String) throws -> [DrumPatternLine] {
        var result: [DrumPatternLine] = []
        
        for rawLine in text.components(separatedBy: "\n") {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let (patternPart, commentPart) = splitLine(trimmed)
            guard !patternPart.isEmpty else { continue }
            guard patternPart.contains(where: { "xXoO123456789".contains($0) }) else { continue }
            
            guard let ref = commentPart, let midiNote = try? resolveReference(ref) else { continue }
            
            result.append(DrumPatternLine(midiNote: midiNote, hits: parseHits(patternPart)))
        }
        
        return result
    }
    
    static func splitLine(_ line: String) -> (pattern: String, comment: String?) {
        guard let hashIdx = line.firstIndex(of: "#") else { return (line, nil) }
        let pattern = String(line[..<hashIdx]).trimmingCharacters(in: .whitespaces)
        let comment = String(line[line.index(after: hashIdx)...]).trimmingCharacters(in: .whitespaces)
        return (pattern, comment.isEmpty ? nil : comment)
    }
    
    // Resolves the text after '#' to a MIDI note number.
    //   - MIDI note number: "36", "47"
    //   - Pad label:        "A.", "A0", "A5", "B3", etc.
    static func resolveReference(_ ref: String) throws -> UInt7 {
        let trimmed = ref.trimmingCharacters(in: .whitespaces)
        
        if let num = Int(trimmed), (0...127).contains(num) {
            return UInt7(num)
        }
        
        if trimmed.count >= 2,
           KOIIGroup(rawValue: String(trimmed.prefix(1)).uppercased()) != nil {
            return try KOIIDevice.noteNumber(padLabel: trimmed)
        }
        
        throw KOIIError.invalidParameter("Invalid reference \"\(trimmed)\". Use a MIDI note number (0–127) or pad label (A., A0, A1–A9, B., etc.)")
    }
    
    static func parseHits(_ pattern: String) -> [UInt7?] {
        pattern.map { char in
            switch char {
            case "x", "X": return UInt7(100)
            case "o", "O": return UInt7(60)
            case "1"..."9": return UInt7(min(127, Int(String(char))! * 14))
            default: return nil
            }
        }
    }
}
