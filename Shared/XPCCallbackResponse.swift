//
//  XPCCallbackResponse.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation

enum XPCCallbackResponse<T: Codable>: Codable {
    private enum Keys: String, CodingKey {
        case type
        case value
    }
    
    private enum Discriminant: String, Codable {
        case success
        case error
    }
    
    init(from decoder: Decoder) throws {
        let d = try decoder.container(keyedBy: Keys.self)
        let discriminant = try d.decode(Discriminant.self, forKey: .type)
        
        switch discriminant {
        case .success:
            let value = try d.decode(T.self, forKey: .value)
            self = .success(value)
        case .error:
            let error = try d.decode(XPCError.self, forKey: .value)
            self = .error(error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case let .success(value):
            try c.encode(Discriminant.success, forKey: .type)
            try c.encode(value, forKey: .value)
        case let .error(error):
            try c.encode(Discriminant.error, forKey: .type)
            try c.encode(error, forKey: .value)
        }
    }
    
    case success(T)
    case error(XPCError)
}
