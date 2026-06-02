//
//  MCP+Ext.swift
//  KOIIController
//
//  Created by xhiew on 2/6/26.
//

import MCP

// MARK: Value helpers
extension Value {
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
}

// MARK: CallTool.Result factories
extension CallTool.Result {
    static func success<T: Encodable>(_ value: T) -> Self {
        Self(content: [.text(text: encodeJSON(value), annotations: nil, _meta: nil)])
    }
    
    static func message(_ text: String) -> Self {
        Self(content: [.text(text: text, annotations: nil, _meta: nil)])
    }
}
