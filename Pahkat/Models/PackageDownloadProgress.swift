//
//  PackageDownloadProgress.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct DownloadError: Error, Codable {
    let message: String
}

enum PackageDownloadStatus: Decodable {
    case notStarted
    case starting
    case progress(downloaded: UInt64, total: UInt64)
    case completed
    case error(DownloadError)
    
    private enum CodingKeys: String, CodingKey {
        case discriminator = "k"
        case value = "v"
    }
    
    private enum Keys: String, Codable {
        case notStarted = "not_started"
        case starting
        case progress
        case completed
        case error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let discriminator = try container.decode(Keys.self, forKey: .discriminator)
        switch discriminator {
        case .notStarted:
            self = .notStarted
        case .starting:
            self = .starting
        case .progress:
            let values = try container.decode([UInt64].self, forKey: .value)
            self = .progress(downloaded: values[0], total: values[1])
        case .completed:
            self = .completed
        case .error:
            let error = try container.decode(DownloadError.self, forKey: .value)
            self = .error(error)
        }
    }
}
