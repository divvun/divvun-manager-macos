//
//  TransactionType.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-19.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import PahkatClient

typealias CancelCallback = () -> Void

protocol TransactionType {
    func processWithCallback(delegate: PackageTransactionDelegate) -> CancelCallback?
    var actions: [TransactionAction<InstallerTarget>] { get }
}

extension PackageTransaction: TransactionType where T == InstallerTarget {
    func processWithCallback(delegate: PackageTransactionDelegate) -> CancelCallback? {
        self.process(delegate: delegate)
        return nil
    }
}
