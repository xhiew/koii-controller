//
//  KOIIMIDIManager.swift
//  KOIIController
//
//  Created by xhiew on 25/5/26.
//

import Foundation
import SwiftMIDI

enum KOIIError: Error, CustomStringConvertible {
    case notConnected
    case deviceNotFound(String)
    case invalidPad(Int)
    case invalidParameter(String)
    
    var description: String {
        switch self {
        case .notConnected:
            return "Not connected to any device."
        case .deviceNotFound(let name):
            return "MIDI device not found: \"\(name)\""
        case .invalidPad(let pad):
            return "Pad number \(pad) is invalid."
        case .invalidParameter(let msg):
            return "Invalid parameter: \(msg)"
        }
    }
}

// Wraps SwiftMIDIIO MIDIManager to manage connection to KO-II.
// Not an actor — MIDIManager handles its own thread-safety internally via PThreadMutex.
final class KOIIMIDIManager: @unchecked Sendable {
    static let shared = KOIIMIDIManager()
    
    private let midi = MIDIManager(
        clientName: "KOIIController",
        model: "KOIIController",
        manufacturer: "xhiew"
    )
    
    private let connectionTag = "koii-output"
    private(set) var connectedDeviceName: String?
    
    private init() {}
    
    func start() throws {
        try midi.start()
    }
    
    func listDestinations() -> [String] {
        midi.endpoints.inputs.map { endpoint in
            endpoint.displayName.isEmpty ? endpoint.name : endpoint.displayName
        }
    }
    
    func connect(deviceName: String) throws {
        guard listDestinations().contains(deviceName) else { throw KOIIError.deviceNotFound(deviceName) }
        
        if connectedDeviceName != nil { disconnect() }
        
        try midi.addOutputConnection(
            to: .inputs(matching: [.name(deviceName)]),
            tag: connectionTag
        )
        
        connectedDeviceName = deviceName
    }
    
    func disconnect() {
        midi.remove(.outputConnection, .withTag(connectionTag))
        connectedDeviceName = nil
    }
    
    var isConnected: Bool {
        connectedDeviceName != nil && midi.managedOutputConnections[connectionTag] != nil
    }
    
    func send(event: MIDIEvent) throws {
        guard let connection = midi.managedOutputConnections[connectionTag] else {
            throw KOIIError.notConnected
        }
        try connection.send(event: event)
    }
    
    func send(events: [MIDIEvent]) throws {
        guard let connection = midi.managedOutputConnections[connectionTag] else {
            throw KOIIError.notConnected
        }
        try connection.send(events: events)
    }
}
