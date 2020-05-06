//
//  JSONValue.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-05-06.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation

indirect enum JSONValue: Codable {
    init(from decoder: Decoder) throws {
        let d = try decoder.singleValueContainer()
        
        if let value = try? d.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? d.decode(Double.self) {
            self = .number(value)
        } else if let value = try? d.decode(String.self) {
            self = .string(value)
        } else if let value = try? d.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? d.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try c.encodeNil()
        case .boolean(let v):
            try c.encode(v)
        case .number(let v):
            try c.encode(v)
        case .string(let v):
            try c.encode(v)
        case .array(let v):
            try c.encode(v)
        case .object(let v):
            try c.encode(v)
        }
    }
    
    case null
    case boolean(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
    
    var string: String? {
        switch self {
        case .string(let v):
            return v
        default:
            return nil
        }
    }

    var object: [String: JSONValue]? {
        switch self {
        case .object(let v):
            return v
        default:
            return nil
        }
    }
}
