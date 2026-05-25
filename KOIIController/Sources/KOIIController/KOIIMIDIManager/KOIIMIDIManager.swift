//
//  MIDIManager.swift
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

    // Start the Core MIDI client. Call once before using anything else.
    func start() throws {
        try midi.start()
    }

    // List all MIDI input destinations visible in the system.
    // These are the endpoints we can SEND MIDI to (e.g. KO-II's MIDI IN).
    func listDestinations() -> [String] {
        midi.endpoints.inputs.map { endpoint in
            endpoint.displayName.isEmpty ? endpoint.name : endpoint.displayName
        }
    }

    // Connect to a device by name. Pass nil to auto-detect the first KO-II found.
    func connect(deviceName: String?) throws {
        let name: String
        if let deviceName {
            name = deviceName
        } else {
            // Auto-detect: look for any endpoint containing "KO" or "EP-133"
            let candidates = midi.endpoints.inputs.filter {
                let n = ($0.displayName.isEmpty ? $0.name : $0.displayName).uppercased()
                return n.contains("KO") || n.contains("EP-133")
            }
            guard let found = candidates.first else {
                throw KOIIError.deviceNotFound("KO-II (auto-detect failed — no matching MIDI destination found)")
            }
            name = found.displayName.isEmpty ? found.name : found.displayName
        }

        // Verify the endpoint exists before connecting
        let exists = midi.endpoints.inputs.contains {
            ($0.displayName.isEmpty ? $0.name : $0.displayName) == name
        }
        guard exists else { throw KOIIError.deviceNotFound(name) }

        // Remove any previous connection
        if connectedDeviceName != nil {
            midi.remove(.outputConnection, .withTag(connectionTag))
        }

        try midi.addOutputConnection(
            to: .inputs(matching: [.name(name)]),
            tag: connectionTag
        )
        connectedDeviceName = name
    }

    // Disconnect the current device.
    func disconnect() {
        midi.remove(.outputConnection, .withTag(connectionTag))
        connectedDeviceName = nil
    }

    var isConnected: Bool {
        connectedDeviceName != nil && midi.managedOutputConnections[connectionTag] != nil
    }

    // Send a single MIDI event to the connected device.
    func send(event: MIDIEvent) throws {
        guard let connection = midi.managedOutputConnections[connectionTag] else {
            throw KOIIError.notConnected
        }
        try connection.send(event: event)
    }

    // Send multiple MIDI events in one call.
    func send(events: [MIDIEvent]) throws {
        guard let connection = midi.managedOutputConnections[connectionTag] else {
            throw KOIIError.notConnected
        }
        try connection.send(events: events)
    }
}
