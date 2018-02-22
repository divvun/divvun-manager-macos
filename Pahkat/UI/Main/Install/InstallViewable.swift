//
//  InstallViewable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct OnStartPackageInfo {
    
}

protocol InstallViewable: class {
    var onCancelTapped: Observable<Void> { get }
    func set(currentPackage info: OnStartPackageInfo)
    func set(totalPackages total: Int)
    func setStarting(action: PackageAction)
    func setEnding(action: PackageAction)
    func showCompletion(isCancelled: Bool, results: [ProcessResult])
    func handle(error: Error)
    func processCancelled()
}
