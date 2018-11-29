//
//  PackageInstallModels.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-07.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct PackageInstallStatusRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension PackageInstallStatusRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "status" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, MacOsInstaller.Targets.system.rawValue] }
}

struct InstallRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension InstallRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "install" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, MacOsInstaller.Targets.system.rawValue] }
}

struct UninstallRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension UninstallRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "uninstall" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, MacOsInstaller.Targets.system.rawValue] }
}
