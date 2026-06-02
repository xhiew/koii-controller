//
//  ResourceHandlers.swift
//  KOIIController
//
//  Created by xhiew on 25/5/26.
//

import Foundation
import MCP

// MARK: ResourceHandler
struct ResourceHandler {
    static func registerResourceHandlers(on server: Server) async {
        await server.withMethodHandler(ListResources.self) { _ in
            ListResources.Result(resources: ResourceDefinition.all)
        }
        
        await server.withMethodHandler(ReadResource.self) { params in
            ReadResource.Result(contents: [content(for: params.uri)])
        }
    }
    
    private static func content(for uri: String) -> Resource.Content {
        switch uri {
        case ResourceDefinition.deviceStatusURI:
            let midi = KOIIMIDIManager.shared
            let payload = DeviceStatusPayload(
                isConnected: midi.isConnected,
                connectedDeviceName: midi.connectedDeviceName
            )
            return .text(encodeJSON(payload), uri: uri, mimeType: "application/json")
            
        case ResourceDefinition.deviceLayoutURI:
            let groups = KOIIGroup.allCases.map { group in
                let base = Int(group.baseNote)
                let groupName = group.rawValue
                // Labels match KOIIDevice.noteNumber(padLabel:) convention
                let padLabels: [(String, Int)] = [
                    ("\(groupName).",  base),
                    ("\(groupName)0",  base + 1),
                    ("\(groupName)FX", base + 2),
                    ("\(groupName)1",  base + 3),
                    ("\(groupName)2",  base + 4),
                    ("\(groupName)3",  base + 5),
                    ("\(groupName)4",  base + 6),
                    ("\(groupName)5",  base + 7),
                    ("\(groupName)6",  base + 8),
                    ("\(groupName)7",  base + 9),
                    ("\(groupName)8",  base + 10),
                    ("\(groupName)9",  base + 11),
                ]
                let pads = Dictionary(uniqueKeysWithValues: padLabels)
                
                return PadGroupLayout(
                    group: group.rawValue,
                    noteRange: [base, base + 11],
                    pads: pads
                )
            }
            
            let payload = DeviceLayoutPayload(groups: groups)
            
            return .text(
                encodeJSON(payload),
                uri: uri,
                mimeType: "application/json"
            )
            
        default:
            return .text(
                #"{"error": "Unknown resource URI: \#(uri)"}"#,
                uri: uri,
                mimeType: "application/json"
            )
        }
    }
}

// MARK: DeviceStatusPayload
struct DeviceStatusPayload: Encodable {
    let isConnected: Bool
    let connectedDeviceName: String?
}

// MARK: PadGroupLayout
struct PadGroupLayout: Encodable {
    let group: String
    let noteRange: [Int]
    let pads: [String: Int]
}

// MARK: DeviceLayoutPayload
struct DeviceLayoutPayload: Encodable {
    let groups: [PadGroupLayout]
}
