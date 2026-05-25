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
        case ResourceDefinition.deviceLayoutURI:
            let groups = KOIIGroup.allCases.map { group in
                let base = Int(group.baseNote)
                let pads = Dictionary(uniqueKeysWithValues: (1...12).map { pad in
                    ("\(pad)", base + (pad - 1))
                })
                
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
