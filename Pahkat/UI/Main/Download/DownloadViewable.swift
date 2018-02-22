//
//  DownloadViewable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


protocol DownloadViewable: class {
    var onCancelTapped: Driver<Void> { get }
    func setStatus(package: Package, status: PackageDownloadStatus)
    func cancel()
    func startInstallation(packages: [Package])
    func handle(error: Error)
}