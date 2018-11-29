//
//  Client.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-11-26.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct PackageRecord : Equatable, Hashable {
    let id: AbsolutePackageKey
    let package: Package
}

public struct AbsolutePackageKey : Equatable, Decodable, Hashable, Comparable {
    let url: String
    let id: String
    let channel: String
    
    public static func < (lhs: AbsolutePackageKey, rhs: AbsolutePackageKey) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    let rawValue: String
    
    init(from url: URL) {
        // TODO: make this less dirty by only selecting the pieces of the URL we want
        let newUrl: URL = {
            var eh = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            eh.fragment = nil
            return eh.url!
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .absoluteURL
        }()
        self.url = newUrl.absoluteString
        self.id = url.lastPathComponent
        self.channel = url.fragment ?? "stable"
        
        let u = newUrl.appendingPathComponent("packages")
            .appendingPathComponent(id)
            .absoluteString
        self.rawValue = "\(u)#\(channel)"
    }
}
