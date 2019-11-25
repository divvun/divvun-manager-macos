//
//  SelectedPackage.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import PahkatClient

struct SelectedPackage: Codable, Equatable, Hashable {
    let key: PackageKey
    let package: Package
    let action: PackageActionType
    let target: InstallerTarget
    
    var isInstalling: Bool {
        switch action {
        case .install:
            return true
        default:
            return false
        }
    }
    
    var isUninstalling: Bool {
        switch action {
        case .uninstall:
            return true
        default:
            return false
        }
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
