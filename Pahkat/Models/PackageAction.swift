//
//  PackageAction.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-01.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum PackageActionType: Codable {
    case install
    case uninstall
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let v = try container.decode(Int.self)
            if let x = PackageActionType.from(rawValue: v) {
                self = x
            } else {
                throw NSError(domain: "", code: 0, userInfo: nil)
            }
        } catch {
            let v = try container.decode(String.self)
            if let x = PackageActionType.from(rawValue: v) {
                self = x
            } else {
                throw error
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.intValue)
    }
    
    var intValue: Int {
        switch self {
        case .install:
            return 0
        case .uninstall:
            return 1
        }
    }
    
    static func from(rawValue: String) -> PackageActionType? {
        switch rawValue {
        case "install":
            return .install
        case "uninstall":
            return .uninstall
        default:
            return nil
        }
    }
    
    static func from(rawValue: Int) -> PackageActionType? {
        switch rawValue {
        case 0:
            return .install
        case 1:
            return .uninstall
        default:
            return nil
        }
    }
}

struct TransactionAction: Codable {
    let action: PackageActionType
    let id: AbsolutePackageKey
    let target: InstallerTarget
}

struct PackageAction: Equatable {
    let action: PackageActionType
    let packageRecord: PackageRecord
    let target: InstallerTarget
    
    init(action: PackageActionType, packageRecord: PackageRecord, target: InstallerTarget) {
        self.action = action
        self.packageRecord = packageRecord
        self.target = target
    }
    
    static func ==(lhs: PackageAction, rhs: PackageAction) -> Bool {
        return lhs.packageRecord == rhs.packageRecord &&
            lhs.target == rhs.target
    }
    
    var isInstalling: Bool {
        if case .install = self.action { return true } else { return false }
    }
    
    var isUninstalling: Bool {
        if case .uninstall = self.action { return true } else { return false }
    }
    
    var description: String {
        switch action {
        case .install:
            return Strings.install
        case .uninstall:
            return Strings.uninstall
        }
    }
}
