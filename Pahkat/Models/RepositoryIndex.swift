//
//  RepositoryIndex.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class RepositoryIndex: Decodable, Hashable, Equatable, Comparable {
    let meta: Repository
    private let packagesMeta: Packages
    private let virtualsMeta: Virtuals
    
    var statuses: [String: PackageStatusResponse] = [:]
    
    init(repository: Repository, packages: Packages, virtuals: Virtuals) {
        self.meta = repository
        self.packagesMeta = packages
        self.virtualsMeta = virtuals
    }
    
    var packages: [String: Package] {
        return packagesMeta.packages
    }
    
    var virtuals: [String: String] {
        return virtualsMeta.virtuals
    }
    
    func url(for package: Package) -> URL {
        return packagesMeta.base.appendingPathComponent(package.id)
    }
    
    func status(for package: Package) -> PackageStatusResponse? {
        return statuses[package.id]
    }
    
    func set(statuses: [String: PackageStatusResponse]) {
        self.statuses = statuses
    }
    
    private enum CodingKeys: String, CodingKey {
        case meta = "meta"
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
    
    var hashValue: Int {
        return meta.hashValue ^ packagesMeta.hashValue ^ virtualsMeta.hashValue
    }
}
