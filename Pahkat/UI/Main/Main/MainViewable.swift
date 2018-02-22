//
//  MainViewable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol MainViewable: class {
    var onPackagesToggled: Observable<[Package]> { get }
    var onPrimaryButtonPressed: Driver<Void> { get }
    func update(title: String)
    func showDownloadView(with packages: [Package])
    func updatePrimaryButton(isEnabled: Bool, label: String)
    func handle(error: Error)
    func setRepository(repo: RepositoryIndex, statuses: [String: PackageInstallStatus])
    func updateSelectedPackages(packages: Set<Package>)
}