//
//  ToolDefinitions.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP

struct ToolDefinition {
    static let all: [Tool] = [
        Tool(
            name: "list_midi_outputs",
            description: "Lists all available MIDI output ports on the system. Call this first to find the KO-II device name before connecting.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "connect_device",
            description: "Connects to a MIDI output port by name. Use the exact port name returned by list_midi_outputs. This server is designed for the Teenage Engineering EP-133 K.O. II — select that device if available.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "device_name": .object([
                        "type": .string("string"),
                        "description": .string("Exact MIDI port name as returned by list_midi_outputs. Always call list_midi_outputs first to get the real name — do NOT guess.")
                    ])
                ]),
                "required": .array([.string("device_name")])
            ])
        ),
        Tool(
            name: "disconnect_device",
            description: "Disconnects from the currently connected MIDI device.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "transport_start",
            description: "Sends MIDI Start message to the KO-II, beginning playback from the start. Requires an active connection — call connect_device first.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "transport_stop",
            description: "Sends MIDI Stop message to the KO-II, stopping playback. Requires an active connection — call connect_device first.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "transport_continue",
            description: "Sends MIDI Continue message to the KO-II, resuming playback from the current position. Requires an active connection — call connect_device first.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "play_pad",
            description: """
            Triggers a single pad on the KO-II. Groups A/B/C/D each have pads 1–12. \
            Use this for single hits, audition, or testing a pad — NOT for grooves or beat patterns. For drum patterns use play_drum_pattern; for melodies use play_key_mode. \
            Requires an active connection — call connect_device first. \
            bpm is required — set it to the KO-II's current tempo. \
            steps_per_beat sets the grid (4=16th, 2=8th, 1=quarter, 3=8th-triplet, 6=16th-triplet, default 4). \
            duration_steps controls how long to hold before noteOff (default 1). \
            The server sends noteOn, waits duration_steps × (60000 / bpm / steps_per_beat) ms, then sends noteOff. \
            MIDI is sent on channel 0 (the KO-II's default).
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "group": .object([
                        "type": .string("string"),
                        "enum": .array([.string("A"), .string("B"), .string("C"), .string("D")]),
                        "description": .string("Group name")
                    ]),
                    "pad": .object([
                        "type": .string("integer"),
                        "minimum": .int(1),
                        "maximum": .int(12),
                        "description": .string("Pad number 1–12")
                    ]),
                    "velocity": .object([
                        "type": .string("integer"),
                        "minimum": .int(0),
                        "maximum": .int(127),
                        "default": .int(80),
                        "description": .string("Velocity 0–127. Common values: 100=hard accent, 80=normal hit, 60=soft, 30=ghost note.")
                    ]),
                    "bpm": .object([
                        "type": .string("integer"),
                        "description": .string("The KO-II's current BPM, as set on the device. Required to calculate hold duration.")
                    ]),
                    "steps_per_beat": .object([
                        "type": .string("integer"),
                        "default": .int(4),
                        "description": .string("Grid subdivision: 1=quarter, 2=eighth, 4=sixteenth, 3=eighth-triplet, 6=sixteenth-triplet.")
                    ]),
                    "duration_steps": .object([
                        "type": .string("integer"),
                        "default": .int(1),
                        "description": .string("How many steps to hold the note before noteOff.")
                    ])
                ]),
                "required": .array([.string("group"), .string("pad"), .string("bpm")])
            ])
        ),
        Tool(
            name: "play_key_mode",
            description: """
            Plays a melodic sequence on the KO-II's Keys Mode using musical scale degrees. \
            Requires an active connection — call connect_device first. \
            The sequence-wide root, scale_name, and octave define the key; each step picks a degree within that scale. \
            Degree is 1-based — degree=1 is the root note. Degrees beyond the scale length wrap into the next octave \
            (e.g. in C major: degree=1 → C, degree=8 → C one octave higher, degree=15 → C two octaves higher). \
            Each step can optionally override the sequence-wide octave to shape melody contour. \
            For atonal or chromatic passages, set scale_name="chromatic" and use degrees 1–12 for the 12 semitones. \
            Octave numbering follows Yamaha convention: C4 = middle C = MIDI 60. Default is octave 5, matching the KO-II hardware's default pitch range. Useful octaves: 3 (low/bass), 4 (middle), 5 (high/default). \
            Position each note by musical time — bar (1-based), beat (1-based within bar), \
            and step_in_beat (1-based subdivision within the beat, default 1). \
            Example: bar=1 beat=3 step_in_beat=1 = downbeat of beat 3; bar=2 beat=1 step_in_beat=3 with steps_per_beat=4 = the 'e' of beat 1 in bar 2. \
            Steps are scheduled concurrently so polyphony and simultaneous notes work correctly. \
            Use steps_per_beat=3 for eighth-triplet feel, 6 for sixteenth-triplet. \
            Call list_available_scales to see all 11 supported scales. \
            MIDI is sent on channel 0 (the KO-II's default). \
            Example: {"bpm":120,"root":"C","scale_name":"major","octave":5,"steps":[{"degree":1,"bar":1,"beat":1},{"degree":3,"bar":1,"beat":2},{"degree":5,"bar":1,"beat":3},{"degree":8,"bar":1,"beat":4},{"degree":5,"bar":2,"beat":1,"octave":6,"duration_steps":4}]}
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "bpm": .object([
                        "type": .string("integer"),
                        "description": .string("The KO-II's current BPM.")
                    ]),
                    "beats_per_bar": .object([
                        "type": .string("integer"),
                        "default": .int(4),
                        "description": .string("Beats per bar. Common signatures: 4/4→4, 3/4→3, 5/4→5, 6/8→6 (pair with steps_per_beat=2). Total steps per bar = beats_per_bar × steps_per_beat.")
                    ]),
                    "steps_per_beat": .object([
                        "type": .string("integer"),
                        "default": .int(4),
                        "description": .string("Grid subdivision: 1=quarter, 2=eighth, 4=sixteenth, 3=eighth-triplet, 6=sixteenth-triplet.")
                    ]),
                    "root": .object([
                        "type": .string("string"),
                        "default": .string("C"),
                        "description": .string("Root note of the scale. Accepts: C, C#/Db, D, D#/Eb, E, F, F#/Gb, G, G#/Ab, A, A#/Bb, B.")
                    ]),
                    "scale_name": .object([
                        "type": .string("string"),
                        "default": .string("major"),
                        "description": .string("Scale name. Call list_available_scales for the full list (major, minor, dorian, phrygian, lydian, mixolydian, locrian, major_pentatonic, minor_pentatonic, blues, chromatic).")
                    ]),
                    "octave": .object([
                        "type": .string("integer"),
                        "minimum": .int(0),
                        "maximum": .int(9),
                        "default": .int(5),
                        "description": .string("Default octave for all steps (per-step octave overrides this). Yamaha convention: C4 = middle C = MIDI 60. Default 5 matches the KO-II hardware default pitch range.")
                    ]),
                    "steps": .object([
                        "type": .string("array"),
                        "description": .string("Array of notes to play."),
                        "items": .object([
                            "type": .string("object"),
                            "properties": .object([
                                "degree": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "description": .string("Scale degree (1-based). 1=root note. Wraps above scale length: in major (7 notes), degree=8 = octave +1, degree=15 = octave +2.")
                                ]),
                                "bar": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "description": .string("Bar number (1-based).")
                                ]),
                                "beat": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "description": .string("Beat within the bar (1-based). Must be ≤ beats_per_bar.")
                                ]),
                                "step_in_beat": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "default": .int(1),
                                    "description": .string("Subdivision within the beat (1-based). Must be ≤ steps_per_beat. With steps_per_beat=4: 1=downbeat, 2=e, 3=and, 4=ah.")
                                ]),
                                "octave": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(0),
                                    "maximum": .int(9),
                                    "description": .string("Optional. Overrides the sequence-wide octave for this single note (useful for melody contour — jumping up/down an octave). Omit to inherit.")
                                ]),
                                "velocity": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(0),
                                    "maximum": .int(127),
                                    "default": .int(80),
                                    "description": .string("Velocity 0–127. Common values: 100=hard accent, 80=normal hit, 60=soft, 30=ghost note.")
                                ]),
                                "duration_steps": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "default": .int(1),
                                    "description": .string("Steps to hold before noteOff. Matters for sustain — longer values give longer notes.")
                                ])
                            ]),
                            "required": .array([.string("degree"), .string("bar"), .string("beat")])
                        ])
                    ])
                ]),
                "required": .array([.string("bpm"), .string("steps")])
            ])
        ),
        Tool(
            name: "play_drum_pattern",
            description: """
            Plays a text-based drum pattern on the KO-II using a compact notation. \
            Requires an active connection — call connect_device first. \
            Each line = one instrument; each character = one grid step. \
            Hit chars: 'x'/'X' = hard (vel 100), 'o'/'O' = soft (vel 60), '1'–'9' = velocity scale (1=14…9=126). Any other char (including '.', '-', or space) = rest. \
            WARNING: every single character (including spaces) counts as one step. Do NOT use spaces to visually group beats — use '.' instead. "x. . . x. . ." is 8 steps, not 4. \
            After '#' identify the instrument using a MIDI note number (0–127) or a pad label (A., A0, A1–A9, AFX, B., B0, B1–B9, etc.). \
            Lines without a valid '#' reference are silently ignored. \
            Pattern length should be a multiple of steps_per_bar (= beats_per_bar × steps_per_beat) so bars align cleanly. Lines shorter than the longest line stay silent for the missing steps. \
            Time signatures: 4/4 with 16th grid → 16 chars/bar; 3/4 with 16th grid → 12 chars/bar; 6/8 (steps_per_beat=2) → 12 chars/bar. \
            All voices are scheduled concurrently for accurate polyphony — no drift. \
            Pass the pattern as a single string with \\n between lines. \
            Example: "x...x...x...x... # 36\\n....x.......x... # 38\\nx.x.x.x.x.x.x.x. # A0" \
            MIDI is sent on channel 0 (the KO-II's default).
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "pattern": .object([
                        "type": .string("string"),
                        "description": .string("Multi-line drum pattern string. Use \\n to separate instrument lines. Length per line should be a multiple of steps_per_bar (= beats_per_bar × steps_per_beat). Every character counts as one step — never use spaces for visual grouping.")
                    ]),
                    "bpm": .object([
                        "type": .string("integer"),
                        "description": .string("The KO-II's current BPM.")
                    ]),
                    "beats_per_bar": .object([
                        "type": .string("integer"),
                        "default": .int(4),
                        "description": .string("Beats per bar. Common signatures: 4/4→4, 3/4→3, 5/4→5, 6/8→6 (pair with steps_per_beat=2).")
                    ]),
                    "steps_per_beat": .object([
                        "type": .string("integer"),
                        "default": .int(4),
                        "description": .string("Grid subdivision: 1=quarter, 2=eighth, 4=sixteenth, 3=eighth-triplet, 6=sixteenth-triplet.")
                    ])
                ]),
                "required": .array([.string("pattern"), .string("bpm")])
            ])
        ),
        Tool(
            name: "list_available_scales",
            description: "Lists all musical scales available for Keys Mode on the KO-II with interval descriptions. Use this to pick the `scale_name` value for play_key_mode. You do NOT need to compute MIDI notes yourself — once you know the scale name, just pass `degree` (1-based) per step and the server resolves the MIDI note automatically.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "start_clock",
            description: """
            Starts sending MIDI Timing Clock to the KO-II at the specified BPM. \
            The clock runs continuously in the background (24 pulses per quarter note) and sets the KO-II's internal tempo. \
            Requires an active connection — call connect_device first. \
            Use this before recording into the KO-II sequencer so the device knows the tempo; \
            then call fire_staged to trigger the staged pattern with zero-jitter sync. \
            Call stop_clock when done to stop sending clock messages. \
            If a clock is already running it will be stopped and restarted at the new BPM.
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "bpm": .object([
                        "type": .string("integer"),
                        "description": .string("Desired tempo in BPM. Must be > 0. Match the BPM used in play_drum_pattern or play_key_mode.")
                    ])
                ]),
                "required": .array([.string("bpm")])
            ])
        ),
        Tool(
            name: "stop_clock",
            description: "Stops the MIDI Timing Clock that was started by start_clock. Safe to call even if no clock is running.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "fire_staged",
            description: """
            Records the most recently staged pattern into the KO-II sequencer. \
            Call this when the user wants to record, save, or write a pattern to the KO-II — for example: \
            "record this", "record the pattern", "record lại pattern vừa rồi", "ghi vào máy", "fire", "save to KO-II". \
            Patterns are automatically staged after every play_drum_pattern or play_key_mode call. \
            Workflow: put the KO-II into record-ready mode, then call fire_staged — the server sends MIDI Start \
            to trigger the KO-II's built-in count-in, waits the same number of beats (countdown_beats, default 4), \
            then fires the notes so they land exactly on bar 1 beat 1 of the recording. \
            Set countdown_beats=0 to skip count-in and fire immediately (useful for live preview, not recording). \
            Throws if nothing has been staged yet — call play_drum_pattern or play_key_mode first.
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "countdown_beats": .object([
                        "type": .string("integer"),
                        "default": .int(4),
                        "description": .string("Beats to wait after MIDI Start before firing notes. Default 4 matches the KO-II's standard 4-beat count-in. Set to 0 to fire immediately with no count-in.")
                    ])
                ])
            ])
        ),
        Tool(
            name: "clear_staged",
            description: "Clears any drum pattern or key mode sequence that was staged (saved) by play_drum_pattern or play_key_mode. Use this when you want to start fresh before composing a new pattern.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
    ]
}
