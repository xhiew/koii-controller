//
//  ResourceDefinitons.swift
//  KOIIController
//
//  Created by xhiew on 25/5/26.
//

import Foundation
import MCP

enum ResourceDefinition {
    static let deviceLayoutURI  = "koii://device/layout"
    static let deviceStatusURI  = "koii://device/status"

    static let all: [Resource] = [
        Resource(
            name: "device-layout",
            uri: deviceLayoutURI,
            description: "KO-II group/pad to MIDI note mapping reference",
            mimeType: "application/json"
        ),
        Resource(
            name: "device-status",
            uri: deviceStatusURI,
            description: "Current MIDI connection state: isConnected, connectedDeviceName",
            mimeType: "application/json"
        )
    ]
}
