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
    var onPackageEvent: Observable<OutlineEvent> { get }
    var onPrimaryButtonPressed: Driver<Void> { get }
    var onSettingsTapped: Driver<Void> { get }
    func update(title: String)
    func showDownloadView(with packages: [URL: PackageAction])
    func updateSettingsButton(isEnabled: Bool)
    func updatePrimaryButton(isEnabled: Bool, label: String)
    func handle(error: Error)
    func setRepositories(data: MainOutlineMap)
    func refreshRepositories()
    func showSettings()
}
