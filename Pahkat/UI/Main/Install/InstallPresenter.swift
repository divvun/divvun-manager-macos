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
    private let packages: [AbsolutePackageKey: PackageAction]
    
    init(view: InstallViewable, packages: [AbsolutePackageKey: PackageAction]) {
        self.view = view
        self.packages = packages
    }
    
    func installTest() -> Single<PackageInstallStatus> {
        // TODO: subprocess
        return Single.just(PackageInstallStatus.notInstalled)
            .delay(2.0, scheduler: MainScheduler.instance)
    }
    
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
        
        let client = PahkatClient()!
        let packages = self.sortPackages()
        let txActions = packages.map {
            return TransactionAction(action: $0.action, id: $0.packageRecord.id, target: $0.target)
        }
        
        cancelToken.childDisposable = client.transaction(of: txActions)
            .asObservable()
            .flatMapLatest { $0.process() }
            .subscribeOn(MainScheduler.instance)
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
