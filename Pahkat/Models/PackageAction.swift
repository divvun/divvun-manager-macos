//
//  PackageAction.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-04-16.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation

struct PackageAction: Equatable, Hashable {
    let key: PackageKey
    let action: PackageActionType
    let target: SystemTarget
}
