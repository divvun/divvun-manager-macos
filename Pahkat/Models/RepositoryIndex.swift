//
//  RepositoryIndex.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

enum InstallerTarget: Codable {
    case system
    case user
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let v = try container.decode(Int.self)
            if let x = InstallerTarget.from(rawValue: v) {
                self = x
            } else {
                throw NSError(domain: "", code: 0, userInfo: nil)
            }
        } catch {
            let v = try container.decode(String.self)
            if let x = InstallerTarget.from(rawValue: v) {
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
        case .system:
            return 0
        case .user:
            return 1
        }
    }
    
    static func from(rawValue: String) -> InstallerTarget? {
        switch rawValue {
        case "system":
            return InstallerTarget.system
        case "user":
            return InstallerTarget.user
        default:
            return nil
        }
    }
    
    static func from(rawValue: Int) -> InstallerTarget? {
        switch rawValue {
        case 0:
            return InstallerTarget.system
        case 1:
            return InstallerTarget.user
        default:
            return nil
        }
    }
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
    
    var statuses: [AbsolutePackageKey: PackageStatusResponse] = [:]
    
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
    
    func status(for key: AbsolutePackageKey) -> PackageStatusResponse? {
        return statuses[key]
    }
    
    func package(for key: AbsolutePackageKey) -> Package? {
        if key.url != meta.base.absoluteString || key.channel != channel.rawValue {
            return nil
        }
        
        return packages[key.id]
    }
    
    @available(*, deprecated, message: "use status(for:)")
    func status(forPackage package: Package) -> PackageStatusResponse? {
        if let key = statuses.keys.first(where: { $0.id == package.id }) {
            return self.status(for: key)
        }
        return nil
    }
    
//    func status(forPackage package: Package) -> PackageStatusResponse? {
//        return statuses[package.id]
//    }
    
    func absoluteKey(for package: Package) -> AbsolutePackageKey {
        var builder = URLComponents(url: meta.base
            .appendingPathComponent("packages")
            .appendingPathComponent(package.id), resolvingAgainstBaseURL: false)!
        builder.fragment = channel.rawValue
        
        return AbsolutePackageKey(from: builder.url!)
    }
    
    func set(statuses: [AbsolutePackageKey: PackageStatusResponse]) {
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
