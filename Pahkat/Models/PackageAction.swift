//
//  PackageAction.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-01.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

@objc enum PackageActionType: Int, Codable {
    case install
    case uninstall
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
