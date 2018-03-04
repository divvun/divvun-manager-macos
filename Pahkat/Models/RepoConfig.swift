//
//  RepoConfig.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct RepoConfig: Codable, Equatable {
    let url: URL
    let channel: Repository.Channels
    
    static func ==(lhs: RepoConfig, rhs: RepoConfig) -> Bool {
        return lhs.url == rhs.url && lhs.channel == rhs.channel
    }
}
