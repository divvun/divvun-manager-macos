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

enum PackageDownloadStatus {
    case notStarted
    case starting
    case progress(downloaded: UInt64, total: UInt64)
    case completed
    case error(DownloadError)
}
