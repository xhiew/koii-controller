//
//  ResourceDefinitons.swift
//  KOIIController
//
//  Created by xhiew on 25/5/26.
//

import Foundation
import MCP

enum KOIIResourceDefinition {
    static let deviceLayoutURI = "koii://device/layout"
    
    static let all: [Resource] = [
        Resource(
            name: "device-layout",
            uri: deviceLayoutURI,
            description: "KO-II group/pad to MIDI note mapping reference",
            mimeType: "application/json"
        )
    ]
}
