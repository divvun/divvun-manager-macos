//
//  PackageInstallStatus.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum PackageInstallStatus: String, Codable {
    case notInstalled
    case upToDate
    case requiresUpdate
    case versionSkipped
    
    var description: String {
        switch self {
        case .notInstalled:
            return Strings.notInstalled
        case .upToDate:
            return Strings.installed
        case .requiresUpdate:
            return Strings.updateAvailable
        case .versionSkipped:
            return Strings.versionSkipped
        }
    }
}
