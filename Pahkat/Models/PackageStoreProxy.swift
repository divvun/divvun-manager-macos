//
//  PackageStoreProxy.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-19.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import PahkatClient

class PackageStoreProxy {
    static let instance = PackageStoreProxy()
    
    private init() {}
    private let adminReceiver = PahkatAdminReceiver.instance
    private let userPackageStore = AppContext.client
    private let jsonEncoder = JSONEncoder()
    
    private func adminTransaction(actions: [TransactionAction<InstallerTarget>]) -> Single<TransactionType> {
        let actionsJsonData = try! self.jsonEncoder.encode(actions)
        let configPath = try! self.userPackageStore.config().configPath()
        
        let tx = Single<TransactionType>.create(subscribe: { emitter in
            let service = self.adminReceiver.service(errorCallback: { error in
                emitter(.error(error))
            })

            service.createAdminTransaction(
                actionsData: actionsJsonData,
                storeConfigPath: configPath
            ) { data in
                do {
                    // Decode the callback data from the XPC admin service
                    let response = try JSONDecoder().decode(XPCCallbackResponse<UInt32>.self, from: data)
                    switch response {
                    case let .success(txId):
                        // Wrap the txId known to the receiver in a proxy
                        let proxy = AdminTransactionProxy(txId: txId, actions: actions)
                        emitter(.success(proxy))
                    case let .error(error):
                        emitter(.error(error))
                    }
                    
                } catch {
                    emitter(.error(error))
                }
            }

            return Disposables.create()
        })

        // Check for admin service availability before trying to create an admin tx
        return PahkatAdminReceiver.checkForAdminService().andThen(tx)
    }
    
    private func userTransaction(actions: [TransactionAction<InstallerTarget>]) -> Single<TransactionType> {
        do {
            return Single.just(try self.userPackageStore.transaction(actions: actions))
        } catch {
            return Single.error(error)
        }
    }
    
    func transaction(actions: [TransactionAction<InstallerTarget>]) -> Single<TransactionType> {
        if actions.contains(where: { $0.target == .system }) {
            return adminTransaction(actions: actions)
        } else {
            return userTransaction(actions: actions)
        }
    }
}
