//
//  XPCTransactionState.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import PahkatClient

enum XPCTransactionStateType: String, Codable {
    case uninstalling
    case installing
    case complete
    case error
    case cancel
}

enum XPCTransactionState: Codable {
    private enum Keys: String, CodingKey {
        case type
        case id
        case packageKey
        case error
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let type = try c.decode(XPCTransactionStateType.self, forKey: .type)
        let id = try c.decode(UInt32.self, forKey: .id)
        
        switch type {
        case .installing:
            let packageKey = try c.decode(PackageKey.self, forKey: .packageKey)
            self = .installing(id: id, packageKey: packageKey)
        case .uninstalling:
            let packageKey = try c.decode(PackageKey.self, forKey: .packageKey)
            self = .installing(id: id, packageKey: packageKey)
        case .complete:
            self = .complete(id: id)
        case .cancel:
            self = .cancel(id: id)
        case .error:
            let error = try c.decode(XPCError.self, forKey: .error)
            self = .error(id: id, error: error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        
        switch self {
        case let .installing(id, packageKey):
            try c.encode(XPCTransactionStateType.installing, forKey: .type)
            try c.encode(id, forKey: .id)
            try c.encode(packageKey, forKey: .packageKey)
        case let .uninstalling(id, packageKey):
            try c.encode(XPCTransactionStateType.uninstalling, forKey: .type)
            try c.encode(id, forKey: .id)
            try c.encode(packageKey, forKey: .packageKey)
        case let .complete(id):
            try c.encode(XPCTransactionStateType.complete, forKey: .type)
            try c.encode(id, forKey: .id)
        case let .cancel(id):
            try c.encode(XPCTransactionStateType.cancel, forKey: .type)
            try c.encode(id, forKey: .id)
        case let .error(id, error):
            try c.encode(XPCTransactionStateType.error, forKey: .type)
            try c.encode(id, forKey: .id)
            try c.encode(error, forKey: .error)
        }
    }
    
    case installing(id: UInt32, packageKey: PackageKey)
    case uninstalling(id: UInt32, packageKey: PackageKey)
    case complete(id: UInt32)
    case cancel(id: UInt32)
    case error(id: UInt32, error: XPCError)
    
    var id: UInt32 {
        switch self {
        case .installing(let id, _):
            return id
        case .uninstalling(let id, _):
            return id
        case .complete(let id):
            return id
        case .cancel(let id):
            return id
        case .error(let id, _):
            return id
        }
    }
    
    var isComplete: Bool {
        switch self {
        case .complete(_):
            return true
        default:
            return false
        }
    }
}
