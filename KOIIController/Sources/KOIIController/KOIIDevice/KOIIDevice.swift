//
//  KOIIDevice.swift
//  KOIIController
//
//  Created by xhiew on 25/5/26.
//

import Foundation
import SwiftMIDI

enum KOIIGroup: String, CaseIterable, Sendable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    
    var baseNote: UInt8 {
        switch self {
        case .a: return 36  // pads 1–12 → notes 36–47 (C2-B2)
        case .b: return 48  // pads 1–12 → notes 48–59 (C3-B3)
        case .c: return 60  // pads 1–12 → notes 60–71 (C4-B4)
        case .d: return 72  // pads 1–12 → notes 72–83 (C5-B5)
        }
    }
}

enum KOIIDevice {
    static let defaultChannel: UInt4 = 0
    
    // MARK: Note mapping
    static func noteNumber(group: KOIIGroup, pad: Int) throws -> UInt7 {
        guard (1...12).contains(pad) else { throw KOIIError.invalidPad(pad) }
        let number = Int(group.baseNote) + (pad - 1)
        
        guard let note = UInt7(exactly: number) else {
            throw KOIIError.invalidParameter("Computed note \(number) is out of MIDI range 0–127")
        }
        
        return note
    }
    
    // Maps physical pad labels (A., A0, A1–A9, AFX) to MIDI note numbers.
    // Physical layout per group (example Group A, base=36):
    //   [A7=45][A8=46][A9=47]
    //   [A4=42][A5=43][A6=44]
    //   [A1=39][A2=40][A3=41]
    //   [A.=36][A0=37][FX=38]
    static func noteNumber(padLabel: String) throws -> UInt7 {
        guard padLabel.count >= 2 else {
            throw KOIIError.invalidParameter("Invalid pad label: \"\(padLabel)\"")
        }
        
        let groupChar = String(padLabel.prefix(1)).uppercased()
        
        guard let group = KOIIGroup(rawValue: groupChar) else {
            throw KOIIError.invalidParameter("Unknown group \"\(groupChar)\" in pad label \"\(padLabel)\"")
        }
        
        let suffix = String(padLabel.dropFirst()).uppercased()
        let offset: Int
        
        switch suffix {
        case ".":
            offset = 0
        case "0":
            offset = 1
        case "FX":
            offset = 2
        default:
            guard let num = Int(suffix), (1...9).contains(num) else {
                throw KOIIError.invalidParameter("Invalid pad label \"\(padLabel)\". Suffix must be '.', '0', 'FX', or 1–9.")
            }
            
            let row = (num - 1) / 3
            let col = (num - 1) % 3
            offset = 3 + (row * 3) + col
        }
        
        let number = Int(group.baseNote) + offset
        
        guard let note = UInt7(exactly: number) else { throw KOIIError.invalidParameter("Computed note \(number) is out of MIDI range 0–127") }
        
        return note
    }
    
    // MARK: Note events
    static func noteOn(
        group: KOIIGroup,
        pad: Int,
        velocity: UInt7 = 80,
        channel: UInt4 = defaultChannel
    ) throws -> MIDIEvent {
        let note = try noteNumber(group: group, pad: pad)
        return .noteOn(note, velocity: .midi1(velocity), channel: channel)
    }
    
    static func noteOff(
        group: KOIIGroup,
        pad: Int,
        channel: UInt4 = defaultChannel
    ) throws -> MIDIEvent {
        let note = try noteNumber(group: group, pad: pad)
        return .noteOff(note, velocity: .midi1(.zero), channel: channel)
    }
    
    static func rawNoteOn(note: UInt7, velocity: UInt7, channel: UInt4 = defaultChannel) -> MIDIEvent {
        .noteOn(note, velocity: .midi1(velocity), channel: channel)
    }
    
    static func rawNoteOff(note: UInt7, channel: UInt4 = defaultChannel) -> MIDIEvent {
        .noteOff(note, velocity: .midi1(.zero), channel: channel)
    }
    
    // MARK: - Control Change
    static func controlChange(cc: UInt7, value: UInt7, channel: UInt4 = defaultChannel) -> MIDIEvent {
        .cc(cc, value: .midi1(value), channel: channel)
    }
    
    // MARK: - Program Change
    static func programChange(program: UInt7, channel: UInt4 = defaultChannel) -> MIDIEvent {
        .programChange(program: program, bank: .noBankSelect, channel: channel)
    }
    
    // MARK: - Transport
    static func transportStart() -> MIDIEvent { .start(.init()) }
    
    static func transportStop() -> MIDIEvent { .stop(.init()) }
    
    static func transportContinue() -> MIDIEvent { .continue(.init()) }
}
