//
//  RepositoryIndex.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct RepositoryIndex: Decodable, Equatable {
    let meta: Repository
    private let packagesMeta: Packages
    private let virtualsMeta: Virtuals
    
    private enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case packagesMeta = "packages"
        case virtualsMeta = "virtuals"
    }
    
//    public static func from(url: URL) -> Observable<RepositoryIndex> {
//        let api = PahkatApiService(baseURL: url)
//
//        api.repositoryIndex().asObservable().subscribe(onNext: { print($0) })
//
//        return Observable.zip(api.repositoryIndex().asObservable(), api.packagesIndex().asObservable(), api.virtualsIndex().asObservable(), resultSelector: {
//            return RepositoryIndex(repository: $0, packages: $1, virtuals: $2)
//        })
//    }
    
    static func ==(lhs: RepositoryIndex, rhs: RepositoryIndex) -> Bool {
        return lhs.meta == rhs.meta &&
            lhs.packagesMeta == rhs.packagesMeta &&
            lhs.virtualsMeta == rhs.virtualsMeta
    }
    
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
}
