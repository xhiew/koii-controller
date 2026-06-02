//
//  PromptHandlers.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP

struct PromptHandler {
    static func registerPromptHandlers(on server: Server) async {
        await server.withMethodHandler(ListPrompts.self) { _ in
            ListPrompts.Result(prompts: PromptDefinition.all)
        }
        
        await server.withMethodHandler(GetPrompt.self) { params in
            try buildPrompt(name: params.name, arguments: params.arguments ?? [:])
        }
    }
    
    private static func buildPrompt(name: String, arguments: [String: String]) throws -> GetPrompt.Result {
        switch name {
        case "beat_generator":
            return try beatGenerator(arguments)
        case "jam_session":
            return try jamSession(arguments)
        default:
            throw KOIIError.invalidParameter("Unknown prompt: \(name)")
        }
    }
}

// MARK: beat_generator
private extension PromptHandler {
    static func beatGenerator(_ args: [String: String]) throws -> GetPrompt.Result {
        guard let genre = args["genre"]?.trimmingCharacters(in: .whitespaces), !genre.isEmpty else {
            throw KOIIError.invalidParameter("genre is required")
        }
        let bpm = args["bpm"] ?? "120"
        let bars = args["bars"] ?? "2"
        
        let text = """
        Generate a \(bars)-bar \(genre) drum beat on the Teenage Engineering KO-II at \(bpm) BPM.
        
        Steps:
        0. Read resource `koii://device/status`. If `isConnected` is true, skip step 1 — the device is already connected.
        1. Call list_midi_outputs to find the KO-II's MIDI port name, then connect_device with that exact name. Do NOT guess the port name.
        2. Design a drum kit. Read resource `koii://device/layout` to see the exact pad label → MIDI note mapping for this device. Common mappings:
           - A.  (MIDI 36) = kick
           - A0  (MIDI 37) = rimshot / side-stick
           - AFX (MIDI 38) = snare
           - A1  (MIDI 39) = clap
           - A4  (MIDI 42) = closed hi-hat
           - A6  (MIDI 44) = open hi-hat
           You may reference by MIDI number (e.g. `# 36`) or pad label (e.g. `# A.`).
        3. Compose a multi-line text pattern for play_drum_pattern:
           - One line per instrument.
           - Each character = one grid step. Use 'x' = hard hit (vel 100), 'o' = soft (vel 60), '1'..'9' = graded velocity, '.' = rest.
           - WARNING: every character including spaces counts as a step. NEVER insert spaces inside the pattern.
           - For 4/4 with 16th grid: 16 chars per bar. For \(bars) bars: 16 × \(bars) chars per line.
           - All lines should be the same length.
        4. Call play_drum_pattern with bpm=\(bpm), beats_per_bar=4, steps_per_beat=4, pattern=<your multi-line string>.
        
        Stylistic guidelines for \(genre):
        - hip-hop / lo-fi: kick on 1 and 3, snare on 2 and 4, swung hi-hats, ghost notes, laid-back feel.
        - boom bap: hard kick on 1, hard snare on 3, ghost snares/hi-hat fills, off-grid micro-timing.
        - techno: four-on-the-floor kick, off-beat open hi-hat on the 'and' of each beat, claps on 2 and 4.
        - house: four-on-the-floor kick, clap on 2 and 4, shuffled off-beat hi-hat.
        - drum-and-bass: 170 BPM-ish, syncopated kick/snare (kick on 1, snare on 3, plus syncopated ghosts), busy hi-hat.
        - trap: kick on 1, snare on 3, fast 8th/16th hi-hats with triplet rolls.
        - jazz: try steps_per_beat=3 for swing feel; sparse ride pattern, brushes feel, leave space.
        
        Make it musical, not robotic. Vary velocities (use the '1'..'9' chars or mix x/o). Leave rest steps for breath. Output the play_drum_pattern call after composing the pattern in your reasoning.
        """
        
        return GetPrompt.Result(
            description: "Generate a \(genre) drum beat at \(bpm) BPM over \(bars) bars on the KO-II.",
            messages: [.user(.text(text: text))]
        )
    }
}

// MARK: jam_session
private extension PromptHandler {
    static func jamSession(_ args: [String: String]) throws -> GetPrompt.Result {
        let mood = args["mood"]?.trimmingCharacters(in: .whitespaces).lowercased() ?? "neutral"
        let key = args["key"] ?? "C"
        let scale = args["scale_name"] ?? "major"
        let bpm = args["bpm"] ?? "100"
        let withDrums = (args["with_drums"]?.lowercased() == "true")
        
        let drumSection = withDrums ? """
        5. Call play_drum_pattern in a separate tool call to add a 1–2 bar rhythmic statement (e.g. kick on beats 1 and 3, snare on beats 2 and 4, light hi-hat). Match the same bpm=\(bpm). Note: tool calls are sequential — play_key_mode runs and finishes completely before play_drum_pattern starts. Keep the drum pattern short so it serves as a rhythmic coda.
        """ : ""
        
        let text = """
        Improvise a melodic phrase on the KO-II Keys Mode in \(key) \(scale) at \(bpm) BPM with a \(mood) mood.
        
        Steps:
        0. Read resource `koii://device/status`. If `isConnected` is true, skip step 1 — the device is already connected.
        1. Call list_midi_outputs to find the KO-II's MIDI port name, then connect_device with that exact name. Do NOT guess.
        2. (Optional) Call list_available_scales if you want to pick a different scale that fits the mood better than "\(scale)".
        3. Design a 4- to 8-bar melody using musical scale degrees with play_key_mode:
           - root="\(key)", scale_name="\(scale)", octave=4 (middle register).
           - Each step picks `degree` (1-based). degree=1 is the root note. In a 7-note scale, degree=8 is the root one octave up.
           - Per-step `octave` override is great for emphasis (jump up or down an octave on key notes).
           - Position notes by `bar` (1-based), `beat` (1-based, ≤ beats_per_bar), and `step_in_beat` (1-based, ≤ steps_per_beat).
           - `velocity` shapes dynamics (0–127). `duration_steps` shapes note length (sustained vs staccato).
        4. Call play_key_mode with bpm=\(bpm), beats_per_bar=4, steps_per_beat=4, and the steps array.\(drumSection)
        
        Stylistic guidelines for "\(mood)" mood:
        - chill: long notes (duration_steps 4–8), soft velocity (50–70), mostly stepwise motion within one octave.
        - dark: prefer minor or phrygian; lower octave (2–3); long sustained notes; occasional half-step descents.
        - energetic: short notes (duration_steps 1–2), high velocity (90–110), wider intervals, octave jumps for accents.
        - sad: minor or dorian; slower phrasing; descending melodic lines; let some notes ring.
        - uplifting: major or lydian; ascending lines; gradual velocity build; resolve on the root or the 5th.
        - neutral / unspecified: balanced phrasing; use whatever serves the music.
        
        Make it expressive. Vary durations and velocities, don't fill every beat, leave breathing room. Output the play_key_mode call after sketching the melody in your reasoning.
        """
        
        return GetPrompt.Result(
            description: "Improvise a \(mood) melody in \(key) \(scale) at \(bpm) BPM on the KO-II.",
            messages: [.user(.text(text: text))]
        )
    }
}
