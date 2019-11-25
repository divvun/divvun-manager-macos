//
//  AdminTransactionProxy.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-19.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import PahkatClient

class AdminTransactionProxy: TransactionType {
    private let txId: UInt32
    private let proxy: Observable<XPCTransactionState>
    private var disposable: Disposable? = nil {
        willSet {
            self.disposable?.dispose()
        }
    }
    
    let actions: [TransactionAction<InstallerTarget>]
    
    init(txId: UInt32, actions: [TransactionAction<InstallerTarget>]) {
        self.txId = txId
        self.actions = actions
        
        proxy = PahkatAdminReceiver.registerProxy(txId: txId)
    }
    
    func processWithCallback(delegate: PackageTransactionDelegate) -> CancelCallback? {
        disposable = proxy.subscribe(onNext: { state in
            DispatchQueue.main.async {
                switch state {
                case let .installing(id, key):
                    delegate.transactionWillInstall(id, packageKey: key)
                case let .uninstalling(id, key):
                    delegate.transactionWillUninstall(id, packageKey: key)
                case let .error(id, error):
                    delegate.transactionDidError(id, packageKey: nil, error: error)
                case let .complete(id):
                    delegate.transactionDidComplete(id)
                case let .cancel(id):
                    delegate.transactionDidCancel(id)
                }
            }
        }, onError: { error in
            DispatchQueue.main.async {
                delegate.transactionDidError(self.txId, packageKey: nil, error: error)
            }
        })
        
        let txId = self.txId
        return {
            let service = PahkatAdminReceiver.instance.service(errorCallback: { err in
                // Give up I suppose.
                print(String(describing: err))
            })
            
            log.debug("Cancelling transaction \(txId)")
            service.cancelTransaction(txId: txId)
        }
    }
    
    deinit {
        self.disposable = nil
    }
}
