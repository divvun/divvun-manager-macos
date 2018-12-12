//
//  InstallViewable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol InstallViewable: class {
    var onCancelTapped: Driver<Void> { get }
    func set(totalPackages total: Int)
    func setStarting(action: PackageActionType, package: Package)
    func setEnding()
    func showCompletion(requiresReboot: Bool)
    func handle(error: Error)
    func beginCancellation()
    func processCancelled()
}
