//
//  PromptDefinitions.swift
//  KOIIController
//
//  Created by xhiew on 23/5/26.
//

import Foundation
import MCP

enum PromptDefinition {
    static let all: [Prompt] = [
        Prompt(
            name: "beat_generator",
            description: "Generates a drum beat in a specific genre on the KO-II using play_drum_pattern.",
            arguments: [
                Prompt.Argument(
                    name: "genre",
                    description: "Music genre (hip-hop, techno, house, drum-and-bass, jazz, trap, lo-fi, ...).",
                    required: true
                ),
                Prompt.Argument(
                    name: "bpm",
                    description: "Tempo in BPM. Default 120.",
                    required: false
                ),
                Prompt.Argument(
                    name: "bars",
                    description: "Pattern length in bars. Default 2.",
                    required: false
                )
            ]
        ),
        Prompt(
            name: "jam_session",
            description: "Improvises a melodic phrase on the KO-II Keys Mode using play_key_mode, optionally with a drum backing.",
            arguments: [
                Prompt.Argument(
                    name: "mood",
                    description: "Mood / feel (chill, dark, energetic, sad, uplifting). Optional.",
                    required: false
                ),
                Prompt.Argument(
                    name: "key",
                    description: "Root note (C, C#/Db, D, ..., B). Default C.",
                    required: false
                ),
                Prompt.Argument(
                    name: "scale_name",
                    description: "Scale name from list_available_scales. Default major.",
                    required: false
                ),
                Prompt.Argument(
                    name: "bpm",
                    description: "Tempo in BPM. Default 100.",
                    required: false
                ),
                Prompt.Argument(
                    name: "with_drums",
                    description: "Layer a simple drum backing (true/false). Default false.",
                    required: false
                )
            ]
        )
    ]
}
