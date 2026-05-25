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
        listMidiOutputs,
        connectDevice,
        disconnectDevice,
        assignGroupChannel,
        playNote,
        playNotes
    ]

    static let listMidiOutputs = Tool(
        name: "list_midi_outputs",
        description: "Lists all available MIDI output ports on the system. Call this first to find the KO-II device name before connecting.",
        inputSchema: .object(["type": .string("object"), "properties": .object([:])])
    )

    static let connectDevice = Tool(
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
    )

    static let disconnectDevice = Tool(
        name: "disconnect_device",
        description: "Disconnects from the currently connected MIDI device and resets the group-to-channel map.",
        inputSchema: .object(["type": .string("object"), "properties": .object([:])])
    )

    static let assignGroupChannel = Tool(
        name: "assign_group_channel",
        description: """
        Maps a KO-II pad group to a MIDI channel for the current session. \
        Call this when a group is in key mode so play_note and play_notes \
        automatically use the correct channel without needing to specify it each time. \
        Check koii://device/channel-map to see current assignments. \
        Assignments reset to channel 1 on disconnect.
        """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "group": .object([
                    "type": .string("string"),
                    "enum": .array([.string("A"), .string("B"), .string("C"), .string("D")]),
                    "description": .string("Pad group to configure")
                ]),
                "channel": .object([
                    "type": .string("integer"),
                    "minimum": .int(1),
                    "maximum": .int(16),
                    "description": .string("MIDI channel 1–16 to assign to this group")
                ])
            ]),
            "required": .array([.string("group"), .string("channel")])
        ])
    )

    static let playNote = Tool(
        name: "play_note",
        description: """
        Plays a single pad on the KO-II. Sends noteOn, waits durationMs, then sends noteOff. \
        Uses the channel assigned via assign_group_channel unless overridden here.
        """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "group": .object([
                    "type": .string("string"),
                    "enum": .array([.string("A"), .string("B"), .string("C"), .string("D")]),
                    "description": .string("Pad group (A=36–47, B=48–59, C=60–71, D=72–83)")
                ]),
                "pad": .object([
                    "type": .string("integer"),
                    "minimum": .int(1),
                    "maximum": .int(12)
                ]),
                "velocity": .object([
                    "type": .string("integer"),
                    "minimum": .int(0),
                    "maximum": .int(127),
                    "default": .int(80)
                ]),
                "durationMs": .object([
                    "type": .string("integer"),
                    "minimum": .int(1),
                    "default": .int(200),
                    "description": .string("Note duration in milliseconds")
                ]),
                "channel": .object([
                    "type": .string("integer"),
                    "minimum": .int(1),
                    "maximum": .int(16),
                    "description": .string("Override MIDI channel 1–16. Omit to use the group's assigned channel.")
                ])
            ]),
            "required": .array([.string("group"), .string("pad")])
        ])
    )

    static let playNotes = Tool(
        name: "play_notes",
        description: """
        Plays multiple pads simultaneously across any groups and channels. \
        All noteOns fire at once; each noteOff fires after its own durationMs (precise per-note timing). \
        Uses each group's assigned channel unless overridden per note. \
        Check koii://device/status before calling and koii://device/channel-map for current assignments.
        """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "notes": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("object"),
                        "properties": .object([
                            "group": .object([
                                "type": .string("string"),
                                "enum": .array([.string("A"), .string("B"), .string("C"), .string("D")])
                            ]),
                            "pad": .object([
                                "type": .string("integer"),
                                "minimum": .int(1),
                                "maximum": .int(12)
                            ]),
                            "velocity": .object([
                                "type": .string("integer"),
                                "minimum": .int(0),
                                "maximum": .int(127),
                                "default": .int(80)
                            ]),
                            "durationMs": .object([
                                "type": .string("integer"),
                                "minimum": .int(1),
                                "default": .int(200)
                            ]),
                            "channel": .object([
                                "type": .string("integer"),
                                "minimum": .int(1),
                                "maximum": .int(16),
                                "description": .string("Override channel for this note. Omit to use the group's assigned channel.")
                            ])
                        ]),
                        "required": .array([.string("group"), .string("pad")])
                    ])
                ])
            ]),
            "required": .array([.string("notes")])
        ])
    )
}
