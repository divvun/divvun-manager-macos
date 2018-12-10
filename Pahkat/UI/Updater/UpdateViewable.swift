//
//  UpdateViewable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol UpdateViewable: class {
    func setPackages(packages: [UpdateTablePackage])
    var onInstallButtonPressed: Driver<Void> { get }
    var onSkipButtonPressed: Driver<Void> { get }
    var onRemindButtonPressed: Driver<Void> { get }
    var onPackageToggled: Observable<UpdateTablePackage> { get }
    func closeWindow()
    func installPackages(packages: [AbsolutePackageKey: PackageAction])
}
