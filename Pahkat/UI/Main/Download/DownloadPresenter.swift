//
//  DownloadPresenter.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class DownloadPresenter {
    private weak var view: DownloadViewable!
    let transaction: PahkatTransactionType
    
    required init(view: DownloadViewable, transaction: PahkatTransactionType) {
        self.view = view
        self.transaction = transaction
    }
    
    func downloadablePackages() -> Observable<(AbsolutePackageKey, Package, InstallerTarget)> {
//        PackageActionType
        // TODO: repositories should be a hashmap with a URL key at this point.
        let keys = transaction.actions.filter { $0.action == .install }
//        let repos = .asSingle()
//
//        Single.zip(repos, Single.just())
//
        return AppContext.store.state.map { $0.repositories }.take(1).asSingle()
            .map { (repos) -> [(AbsolutePackageKey, Package, InstallerTarget)] in
                var packages = [(AbsolutePackageKey, Package, InstallerTarget)]()
                for repo in repos {
                    let nextPackages = keys.compactMap { k -> (AbsolutePackageKey, Package, InstallerTarget)? in
                        if let p = repo.package(for: k.id) { return (k.id, p, k.target) } else { return nil }
                    }
                    packages.append(contentsOf: nextPackages)
                }
                return packages
            }.asObservable().flatMapLatest {
                return Observable.from($0)
            }
    }
    
    private func bindCancel() -> Disposable {
        return view.onCancelTapped.drive(onNext: { [weak self] in self?.view.cancel() })
    }
    
    private func bindDownload() -> Disposable {
        let client = AppContext.client
        
        return downloadablePackages().map { (args: (AbsolutePackageKey, Package, InstallerTarget)) -> Observable<(Package, PackageDownloadStatus)> in
            let (id, package, target) = args
            log.debug("Downloading \(id)")
            
            return client.download(packageKey: id, target: target)
                .do(onNext: { [weak self] x in
                    self?.view.setStatus(package: package, status: x.status)
                })
                .map { (package, $0.status) }
            }
            .merge(maxConcurrent: 3)
            .toArray()
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.view.startInstallation(transaction: self.transaction)
                },
                onError: { [weak self] in
                    self?.view.handle(error: $0)
                })
    }
        
    func start() -> Disposable {
        _ = downloadablePackages().map({ $0.1 }).toArray().subscribe(onNext: {
            self.view.initializeDownloads(packages: $0)
        })
        
        return CompositeDisposable(disposables: [
            self.bindDownload(),
            self.bindCancel()
        ])
    }
}
