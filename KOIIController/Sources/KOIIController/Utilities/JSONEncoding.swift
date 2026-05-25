//
//  JSONEncoding.swift
//  KOIIController
//
//  Created by xhiew on 25/5/26.
//

import Foundation

extension JSONEncoder {
    static let pretty: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

func encodeJSON<T: Encodable>(_ value: T, using encoder: JSONEncoder = .pretty) -> String {
    guard let data = try? encoder.encode(value),
          let json = String(data: data, encoding: .utf8) else {
        return #"{"error": "encoding failed"}"#
    }
    return json
}
