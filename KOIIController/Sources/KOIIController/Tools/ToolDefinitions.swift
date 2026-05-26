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
            description: "Connects to a MIDI output port by name. This server is designed for the Teenage Engineering EP-133 K.O. II — select that device if available.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "deviceName": .object([
                        "type": .string("string"),
                        "description": .string("Exact MIDI port name as returned by list_midi_outputs")
                    ])
                ]),
                "required": .array([.string("deviceName")])
            ])
        ),
        Tool(
            name: "disconnect_device",
            description: "Disconnects from the currently connected MIDI device.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "transport_start",
            description: "Sends MIDI Start message to the KO-II, beginning playback from the start.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "transport_stop",
            description: "Sends MIDI Stop message to the KO-II, stopping playback.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "transport_continue",
            description: "Sends MIDI Continue message to the KO-II, resuming playback from the current position.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])])
        ),
        Tool(
            name: "play_pad",
            description: """
            Triggers a single pad on the KO-II. Groups A/B/C/D each have pads 1–12. \
            To hold the note for a musical duration, provide bpm (the KO-II's current tempo), \
            steps_per_beat (grid: 4=16th, 2=8th, 1=quarter, 3=8th-triplet, 6=16th-triplet), and duration_steps (how many steps to hold). \
            The server sends noteOn, waits duration_steps × (60000 / bpm / steps_per_beat) ms, then sends noteOff. \
            If bpm is omitted the note is triggered immediately with no hold.
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
            All steps share the same bpm and steps_per_beat grid. \
            Each step specifies which group/pad to hit, when to fire (offset_steps from sequence start), \
            and how long to hold (duration_steps). \
            Steps are scheduled concurrently so polyphony and simultaneous hits work correctly. \
            step_duration_ms = 60000 / bpm / steps_per_beat. \
            Use steps_per_beat=3 for eighth-triplet feel, 6 for sixteenth-triplet.
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "bpm": .object([
                        "type": .string("number"),
                        "description": .string("The KO-II's current BPM.")
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
                                "offset_steps": .object([
                                    "type": .string("integer"),
                                    "minimum": .int(0),
                                    "description": .string("Step position from sequence start (0-based).")
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
                            "required": .array([.string("group"), .string("pad"), .string("offset_steps")])
                        ])
                    ])
                ]),
                "required": .array([.string("bpm"), .string("steps")])
            ])
        )
    ]
}
