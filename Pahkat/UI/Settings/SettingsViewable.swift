//
//  SettingsViewable.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol SettingsViewable: class {
    func setRepositories(repositories: [RepositoryTableRowData])
    var onAddRepoButtonTapped: Driver<Void> { get }
    var onRemoveRepoButtonTapped: Driver<Void> { get }
    func updateProgressIndicator(isEnabled: Bool)
    func addBlankRepositoryRow()
    func promptRemoveRepositoryRow()
    func handle(error: Error)
}
