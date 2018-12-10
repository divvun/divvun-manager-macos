//
//  RepositoryIndex.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

@objc enum InstallerTarget: Int, Codable {
    case system
    case user
}

struct PackageStatusResponse : Codable {
    let status: PackageInstallStatus
    let target: InstallerTarget
}

@objc class RepositoryIndex: NSObject, Decodable, Comparable {
    let meta: Repository
    let channel: Repository.Channels
    private let packagesMeta: Packages
    private let virtualsMeta: Virtuals
    
    var statuses: [String: PackageStatusResponse] = [:]
    
    init(repository: Repository, packages: Packages, virtuals: Virtuals, channel: Repository.Channels) {
        self.meta = repository
        self.packagesMeta = packages
        self.virtualsMeta = virtuals
        self.channel = channel
    }
    
    var packages: [String: Package] {
        return packagesMeta.packages
    }
    
    var virtuals: [String: String] {
        return virtualsMeta.virtuals
    }
    
//    func url(for package: Package) -> URL {
//        return packagesMeta.base.appendingPathComponent(package.id)
//    }
    
    func status(for package: Package) -> PackageStatusResponse? {
        return statuses[package.id]
    }
    
    func absoluteKey(for package: Package) -> AbsolutePackageKey {
        var builder = URLComponents(url: meta.base
            .appendingPathComponent("packages")
            .appendingPathComponent(package.id), resolvingAgainstBaseURL: false)!
        builder.fragment = channel.rawValue
        
        return AbsolutePackageKey(from: builder.url!)
    }
    
    func set(statuses: [String: PackageStatusResponse]) {
        self.statuses = statuses
    }
    
    private enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case channel = "channel"
        case packagesMeta = "packages"
        case virtualsMeta = "virtuals"
    }
    
    static func ==(lhs: RepositoryIndex, rhs: RepositoryIndex) -> Bool {
        return lhs.meta == rhs.meta &&
            lhs.packagesMeta == rhs.packagesMeta &&
            lhs.virtualsMeta == rhs.virtualsMeta
    }
    
    static func <(lhs: RepositoryIndex, rhs: RepositoryIndex) -> Bool {
        // BTree keys break if you don't break contention yourself...
        if lhs.meta.nativeName == rhs.meta.nativeName {
            return lhs.hashValue < rhs.hashValue
        }
        return lhs.meta.nativeName < rhs.meta.nativeName
    }
    
//    override var hashValue: Int {
//        return meta.hashValue ^ packagesMeta.hashValue ^ virtualsMeta.hashValue
//    }
}
