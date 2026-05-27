//
//  ScaleModel.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP
import SwiftMIDI

// MARK: KOIIScaleLibrary
enum KOIIScaleLibrary {
    static let patterns: [String: [Int]] = [
        "major": [0, 2, 4, 5, 7, 9, 11],
        "minor": [0, 2, 3, 5, 7, 8, 10],
        "dorian": [0, 2, 3, 5, 7, 9, 10],
        "phrygian": [0, 1, 3, 5, 7, 8, 10],
        "lydian": [0, 2, 4, 6, 7, 9, 11],
        "mixolydian": [0, 2, 4, 5, 7, 9, 10],
        "locrian": [0, 1, 3, 5, 6, 8, 10],
        "major_pentatonic": [0, 2, 4, 7, 9],
        "minor_pentatonic": [0, 3, 5, 7, 10],
        "blues": [0, 3, 5, 6, 7, 10],
        "chromatic": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    ]
    
    static let noteToSemitone: [String: Int] = [
        "C": 0,
        "C#": 1,
        "Db": 1,
        "D": 2,
        "D#": 3,
        "Eb": 3,
        "E": 4,
        "F": 5,
        "F#": 6,
        "Gb": 6,
        "G": 7,
        "G#": 8,
        "Ab": 8,
        "A": 9,
        "A#": 10,
        "Bb": 10,
        "B": 11
    ]
    
    static let descriptions: [String: String] = [
        "major": "Major scale (W-W-H-W-W-W-H), intervals: [0,2,4,5,7,9,11]",
        
        "minor": "Natural minor scale (W-H-W-W-H-W-W), intervals: [0,2,3,5,7,8,10]",
        
        "dorian": "Dorian mode (W-H-W-W-W-H-W), intervals: [0,2,3,5,7,9,10]",
        
        "phrygian": "Phrygian mode (H-W-W-W-H-W-W), intervals: [0,1,3,5,7,8,10]",
        
        "lydian": "Lydian mode (W-W-W-H-W-W-H), intervals: [0,2,4,6,7,9,11]",
        
        "mixolydian": "Mixolydian mode (W-W-H-W-W-H-W), intervals: [0,2,4,5,7,9,10]",
        
        "locrian": "Locrian mode (H-W-W-H-W-W-W), intervals: [0,1,3,5,6,8,10]",
        
        "major_pentatonic": "Major pentatonic (major without 4th/7th), intervals: [0,2,4,7,9]",
        
        "minor_pentatonic": "Minor pentatonic (minor without 2nd/6th), intervals: [0,3,5,7,10]",
        
        "blues": "Blues scale (minor pentatonic + b5), intervals: [0,3,5,6,7,10]",
        
        "chromatic": "Chromatic scale (all 12 semitones), intervals: [0..11]"
    ]
}
