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
    
    private func loadAppropriateRPC() -> Single<PahkatRPCService> {
        if packages.values.first(where: { $0.target == .system }) != nil {
            if let rpc = PahkatRPCService(requiresAdmin: true) {
                return AppContext.settings.state.take(1)
                    .map { $0.repositories }
                    .flatMapLatest { try rpc.repository(with: $0[0]) }
                    .map { _ in rpc }
                    .asSingle()
            }
            return Single.error(RPCError(message: "Could not get RPC"))
        } else {
            return Single.just(AppContext.rpc)
        }
    }
    
    private func sortPackages() -> [PackageAction] {
        return packages.values
            .sorted(by: { (a, b) in
                if (a.isInstalling && b.isInstalling) || (a.isUninstalling && b.isUninstalling) {
                    // TODO: fix when dependency management is added
                    return a.package.id < b.package.id
                }
                
                return a.isUninstalling
            })
    }
    
    private func parseAction(rpc: PahkatRPCService, action: PackageAction, cancelToken: CancelToken) throws -> Observable<PackageInstallStatus> {
        if cancelToken.isCancelled {
            return Observable.empty()
        }
        
        switch action {
        case let .install(repo, package, target):
            return try rpc.install(package, repo: repo, target: target).do(
                onSuccess: ({ _ in
                    self.view.setEnding(action: action)
                }),
                onSubscribe: {
                    self.view.setStarting(action: action)
                })
                .asObservable()
        case let .uninstall(repo, package, target):
            return try rpc.uninstall(package, repo: repo, target: target).do(
                onSuccess: ({ _ in
                    self.view.setEnding(action: action)
                }),
                onSubscribe: {
                    self.view.setStarting(action: action)
                })
                .asObservable()
        }
    }
    
    private func bindInstallProcess() -> CancelToken {
        let cancelToken = CancelToken()
        
        cancelToken.childDisposable = loadAppropriateRPC().asObservable()
            .flatMapLatest { [weak self] (rpc: PahkatRPCService) -> Observable<PackageInstallStatus> in
                guard let `self` = self else { return Observable.empty() }
                let packages = self.sortPackages()
                
                return Observable.from(try packages.map { action in
                    return try self.parseAction(rpc: rpc, action: action, cancelToken: cancelToken)
                }).merge(maxConcurrent: 1)
            }
            .toArray()
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if cancelToken.isCancelled {
                    self?.view.processCancelled()
                } else {
                    self?.view.showCompletion()
                }
            }, onError: { [weak self] error in
                self?.view.handle(error: error)
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
