//
//  PackageAction.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-01.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum PackageAction: Hashable {
    case install(RepositoryIndex, PackageRecord, MacOsInstaller.Targets)
    case uninstall(RepositoryIndex, PackageRecord, MacOsInstaller.Targets)
    
    static func ==(lhs: PackageAction, rhs: PackageAction) -> Bool {
        return lhs.repository == rhs.repository &&
            lhs.packageRecord == rhs.packageRecord &&
            lhs.target == rhs.target
    }
    
    var isInstalling: Bool {
        if case .install = self { return true } else { return false }
    }
    
    var isUninstalling: Bool {
        if case .uninstall = self { return true } else { return false }
    }
    
    var hashValue: Int {
        return self.repository.hashValue ^ self.packageRecord.hashValue ^ self.target.hashValue
    }
    
    var repository: RepositoryIndex {
        switch self {
        case let .install(repo, _, _):
            return repo
        case let .uninstall(repo, _, _):
            return repo
        }
    }
    
    var packageRecord: PackageRecord {
        switch self {
        case let .install(_, package, _):
            return package
        case let .uninstall(_, package, _):
            return package
        }
    }
    
    var target: MacOsInstaller.Targets {
        switch self {
        case let .install(_, _, target):
            return target
        case let .uninstall(_, _, target):
            return target
        }
    }
    
    var description: String {
        switch self {
        case .install:
            return Strings.install
        case .uninstall:
            return Strings.uninstall
        }
    }
}
