//
//  InstallPresenter.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-19.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

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
    private let transaction: PahkatTransactionType
    
    init(view: InstallViewable, transaction: PahkatTransactionType) {
        self.view = view
        self.transaction = transaction
    }
    
    func installTest() -> Single<PackageInstallStatus> {
        // TODO: subprocess
        return Single.just(PackageInstallStatus.notInstalled)
            .delay(2.0, scheduler: MainScheduler.instance)
    }
    
    private func bindInstallProcess() -> CancelToken {
        let cancelToken = CancelToken()
        
        let repos = AppContext.store.state.map { $0.repositories }.take(1)
        
        let observable = Observable.combineLatest(repos, transaction.process())
        
        var requiresReboot = false
        
        cancelToken.childDisposable = observable
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (repos, event) in
                var maybePackage: Package? = nil
                
                for repo in repos {
                    maybePackage = repo.packages[event.packageId.id]
                    if maybePackage != nil {
                        break
                    }
                }
                
                if maybePackage == nil {
                    fatalError("No package found for id: \(event.packageId)")
                }
                
                let package = maybePackage!
                
                
                
                guard let action = self.transaction.actions.first(where: { $0.id == event.packageId }) else {
                    return
                }
                
                switch event.event {
                case .installing:
                    self.view.setStarting(action: action.action, package: package)
                    if package.nativeInstaller?.requiresReboot ?? false {
                        requiresReboot = true
                    }
                case .uninstalling:
                    self.view.setStarting(action: action.action, package: package)
                    if package.nativeInstaller?.requiresUninstallReboot ?? false {
                        requiresReboot = true
                    }
                case .completed:
                    self.view.setEnding()
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
                    self?.view.showCompletion(requiresReboot: requiresReboot)
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
        self.view.set(totalPackages: transaction.actions.count)
        
        return Disposables.create { }
    }
    
    func install() -> CancelToken {
        return bindInstallProcess()
    }
}
