//
//  Repository.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-07.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct RepositoryRequest: Codable {
    let config: RepoConfig
}

extension RepositoryRequest: JSONRPCRequest {
    typealias Response = RepositoryIndex
    
    var method: String { return "repository" }
    var params: Encodable? { return [config.url.absoluteString, config.channel.rawValue] }
}

struct RepositoryStatusesRequest {
    let url: URL
}

struct PackageStatusResponse: Codable {
    let status: PackageInstallStatus
    let target: MacOsInstaller.Targets
}

extension RepositoryStatusesRequest: JSONRPCRequest {
    typealias Response = [String: PackageStatusResponse]
    
    var method: String { return "repository_statuses" }
    var params: Encodable? { return [url.absoluteString] }
}

struct DownloadSubscriptionRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension DownloadSubscriptionRequest: JSONRPCSubscriptionRequest {
    typealias Response = [UInt64]
    
    var method: String { return "download_subscribe" }
    var unsubscribeMethod: String? { return "download_unsubscribe" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, MacOsInstaller.Targets.system.rawValue] }
    var callback: String { return "download" }
}
