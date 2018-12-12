//
//  Client.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-11-26.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct PackageRecord : Equatable, Hashable, Codable {
    let id: AbsolutePackageKey
    let package: Package
}

public struct AbsolutePackageKey : Codable, Hashable, Comparable {
    let url: String
    let id: String
    let channel: String
    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self.init(from: URL(string: string)!)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    public static func < (lhs: AbsolutePackageKey, rhs: AbsolutePackageKey) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public static func == (lhs: AbsolutePackageKey, rhs: AbsolutePackageKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
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
