//
//  APIService+Extensions.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-20.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

extension Package.Installer {
    var size: Int64 {
        switch self {
        case let .windowsInstaller(installer):
            return Int64(installer.size)
        case let .macOsInstaller(installer):
            return Int64(installer.size)
        case let .tarballInstaller(installer):
            return Int64(installer.size)
        }
    }
}
