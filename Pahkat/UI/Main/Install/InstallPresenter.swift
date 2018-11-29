//
//  InstallPresenter.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-19.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct RPCError: Error {
    let message: String
}

class CancelToken {
    private(set) var isCancelled: Bool = false
    var childDisposable: Disposable?
    
    func cancel() {
        isCancelled = true
    }
    
    deinit {
        self.childDisposable?.dispose()
    }
}

class InstallPresenter {
    private unowned var view: InstallViewable
    private let packages: [URL: PackageAction]
    
    init(view: InstallViewable, packages: [URL: PackageAction]) {
        self.view = view
        self.packages = packages
    }
    
    func installTest() -> Single<PackageInstallStatus> {
        // TODO: subprocess
        return Single.just(PackageInstallStatus.notInstalled)
            .delay(2.0, scheduler: MainScheduler.instance)
    }
    
//    private func loadAppropriateRPC() -> Single<PahkatRPCService> {
//        if packages.values.first(where: { $0.target == .system }) != nil {
//            if let rpc = PahkatRPCService(requiresAdmin: true) {
//                return AppContext.settings.state.take(1)
//                    .map { $0.repositories }
//                    .flatMapLatest { try rpc.repository(with: $0[0]) }
//                    .map { _ in rpc }
//                    .asSingle()
//            }
//            return Single.error(RPCError(message: "Could not get RPC"))
//        } else {
//            return Single.just(AppContext.rpc)
//        }
//    }
    
    private func sortPackages() -> [PackageAction] {
        return packages.values
            .sorted(by: { (a, b) in
                if (a.isInstalling && b.isInstalling) || (a.isUninstalling && b.isUninstalling) {
                    // TODO: fix when dependency management is added
                    return a.packageRecord.id < b.packageRecord.id
                }
                
                return a.isUninstalling
            })
    }
    
    private func bindInstallProcess() -> CancelToken {
        let cancelToken = CancelToken()
        
        let client = PahkatClient()
        // TODO: re-add admin mechanism for installing things
        let packages = self.sortPackages()
        
        let tx = client.transaction(of: packages)
        
        cancelToken.childDisposable = tx.process()
//            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { event in
                guard let action = packages.first(where: { $0.packageRecord.id == event.packageId }) else {
                    fatalError("No package found for id: \(event.packageId)")
                }
                
                switch event.event {
                case .installing, .uninstalling:
                    self.view.setStarting(action: action)
                case .completed:
                    self.view.setEnding(action: action)
                case .notStarted:
                    break
                case .error:
                    break // TODO
                }
            },
            onError: { [weak self] error in
                self?.view.handle(error: error)
            },
            onCompleted: { [weak self] in
                if cancelToken.isCancelled {
                    self?.view.processCancelled()
                } else {
                    self?.view.showCompletion()
                }
            })
        
        return cancelToken
    }
    
    private func bindCancelButton() -> Disposable {
        return view.onCancelTapped.drive(onNext: { [weak self] in
            self?.view.beginCancellation()
        })
    }
    
    func start() -> Disposable {
        self.view.set(totalPackages: packages.count)
        
        return Disposables.create { }
    }
    
    func install() -> CancelToken {
        return bindInstallProcess()
    }
}
