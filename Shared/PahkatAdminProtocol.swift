//
//  PahkatAdminProtocol.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import ServiceManagement
import PahkatClient

@objc protocol PahkatAdminProtocol {
    func xpcServiceVersion(withReply: @escaping (String) -> ())
    func set(cachePath: String, for configPath: String)
    func set(channel: String, for configPath: String)
    func createAdminTransaction(
        actionsData: /* [TransactionAction] as JSON */ Data,
        storeConfigPath configPath: String,
        txIdCallback callback: @escaping (/* XPCCallbackResponse as JSON */ Data) -> ()
    )
    func processTransaction(txId: UInt32)
    func cancelTransaction(txId: UInt32)
}
