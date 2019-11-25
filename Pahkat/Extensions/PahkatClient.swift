//
//  PahkatClient.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-20.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import PahkatClient

extension MacOSPackageStore {
    func repoIndexesWithStatuses() throws -> [RepositoryIndex] {
        let repos = try self.repoIndexes()
        
        return try repos.map { repo in
            let record = RepoRecord(url: repo.meta.base, channel: repo.channel)
            let userStatuses = try self.allStatuses(repo: record, target: .user)
            var systemStatuses = try self.allStatuses(repo: record, target: .system)
            
            for (k, v) in userStatuses {
                if !v.status.isError() && v.status != .notInstalled {
                    systemStatuses[k] = v
                }
            }
            
            var statuses = [PackageKey: PackageStatusResponse]()
            
            for (k, v) in systemStatuses {
                var builder = URLComponents(
                    url: repo.meta.base
                        .appendingPathComponent("packages")
                        .appendingPathComponent(k),
                    resolvingAgainstBaseURL: false)!
                builder.fragment = repo.channel.rawValue
                
                let key = PackageKey(from: builder.url!)
                statuses[key] = v
            }
            
            repo.statuses = statuses
            return repo
        }
    }
}
