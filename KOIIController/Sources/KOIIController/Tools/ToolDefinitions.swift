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
                        "description": .string("Exact MIDI port name as returned by list_midi_outputs")
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
            Requires an active connection — call connect_device first. \
            bpm is required — set it to the KO-II's current tempo. \
            steps_per_beat sets the grid (4=16th, 2=8th, 1=quarter, 3=8th-triplet, 6=16th-triplet, default 4). \
            duration_steps controls how long to hold before noteOff (default 1). \
            The server sends noteOn, waits duration_steps × (60000 / bpm / steps_per_beat) ms, then sends noteOff.
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
                        "description": .string("Velocity 0–127, default 80")
                    ]),
                    "bpm": .object([
                        "type": .string("number"),
                        "description": .string("The KO-II's current BPM, as set on the device. Required to calculate hold duration.")
                    ]),
                    "steps_per_beat": .object([
                        "type": .string("integer"),
                        "description": .string("Grid subdivision: 1=quarter, 2=eighth, 4=sixteenth, 3=eighth-triplet, 6=sixteenth-triplet. Default 4.")
                    ]),
                    "duration_steps": .object([
                        "type": .string("integer"),
                        "description": .string("How many steps to hold the note before noteOff. Default 1.")
                    ])
                ]),
                "required": .array([.string("group"), .string("pad"), .string("bpm")])
            ])
        ),
        Tool(
            name: "play_sequence",
            description: """
            Plays multiple pads with precise timing on the KO-II. \
            Requires an active connection — call connect_device first. \
            All steps share the same bpm, beats_per_bar, and steps_per_beat grid. \
            Position each note by musical time — bar (1-based), beat (1-based within bar), \
            and step_in_beat (1-based subdivision within the beat, default 1). \
            Example: bar=1 beat=3 step_in_beat=1 = downbeat of beat 3; bar=2 beat=1 step_in_beat=3 with steps_per_beat=4 = the 'e' of beat 1 in bar 2. \
            Steps are scheduled concurrently so polyphony and simultaneous hits work correctly. \
            Use steps_per_beat=3 for eighth-triplet feel, 6 for sixteenth-triplet.
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "bpm": .object([
                        "type": .string("number"),
                        "description": .string("The KO-II's current BPM.")
                    ]),
                    "beats_per_bar": .object([
                        "type": .string("integer"),
                        "description": .string("Beats per bar. Common signatures: 4/4→4, 3/4→3, 5/4→5, 6/8→6 (pair with steps_per_beat=2). Total steps per bar = beats_per_bar × steps_per_beat. Default 4.")
                    ]),
                    "steps_per_beat": .object([
                        "type": .string("integer"),
                        "description": .string("Grid subdivision: 1=quarter, 2=eighth, 4=sixteenth, 3=eighth-triplet, 6=sixteenth-triplet. Default 4.")
                    ]),
                    "steps": .object([
                        "type": .string("array"),
                        "description": .string("Array of notes to play."),
                        "items": .object([
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
                                "bar": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "description": .string("Bar number (1-based).")
                                ]),
                                "beat": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "description": .string("Beat within the bar (1-based).")
                                ]),
                                "step_in_beat": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(1),
                                    "description": .string("Subdivision within the beat (1-based, default 1). With steps_per_beat=4: 1=downbeat, 2=e, 3=and, 4=ah.")
                                ]),
                                "velocity": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(0),
                                    "maximum": .int(127),
                                    "description": .string("Velocity 0–127, default 80.")
                                ]),
                                "duration_steps": .object([
                                    "type": .string("integer"),
                                    "description": .string("Steps to hold before noteOff. Default 1.")
                                ])
                            ]),
                            "required": .array([.string("group"), .string("pad"), .string("bar"), .string("beat")])
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
            Hit chars: 'x'/'X' = hard (vel 100), 'o'/'O' = soft (vel 60), '1'–'9' = velocity scale (1=14…9=126), any other char = rest. \
            After '#' identify the instrument using a MIDI note number (0–127) or a pad label (A., A0, A1–A9, AFX, B., B0, B1–B9, etc.). \
            Lines without a valid '#' reference are silently ignored. \
            Pattern length determines bar count: steps_per_bar = beats_per_bar × steps_per_beat. \
            Time signatures: 4/4 with 16th grid → 16 chars/bar; 3/4 with 16th grid → 12 chars/bar; 6/8 (steps_per_beat=2) → 12 chars/bar. \
            All voices are scheduled concurrently for accurate polyphony — no drift. \
            Pass the pattern as a single string with \\n between lines. \
            Example: "x...x...x...x...  # 36\\n....x.......x...  # 38\\nx.x.x.x.x.x.x.x.  # A0"
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "pattern": .object([
                        "type": .string("string"),
                        "description": .string("Multi-line drum pattern string. Use \\n to separate instrument lines.")
                    ]),
                    "bpm": .object([
                        "type": .string("number"),
                        "description": .string("The KO-II's current BPM.")
                    ]),
                    "beats_per_bar": .object([
                        "type": .string("integer"),
                        "description": .string("Beats per bar. Common signatures: 4/4→4, 3/4→3, 5/4→5, 6/8→6 (pair with steps_per_beat=2). Default 4.")
                    ]),
                    "steps_per_beat": .object([
                        "type": .string("integer"),
                        "description": .string("Grid subdivision: 1=quarter, 2=eighth, 4=sixteenth (default), 3=eighth-triplet, 6=sixteenth-triplet.")
                    ])
                ]),
                "required": .array([.string("pattern"), .string("bpm")])
            ])
        ),
        Tool(
            name: "list_available_scales",
            description: "Lists all musical scales available for Keys Mode on the KO-II, with interval descriptions. Call this to discover valid scale_name values for play_scale_sequence.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        )
    ]
}
