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
    let packages: [AbsolutePackageKey: PackageAction]
    
    required init(view: DownloadViewable, packages: [AbsolutePackageKey: PackageAction]) {
        self.view = view
        self.packages = packages
    }
    
    func downloadablePackages() -> [AbsolutePackageKey: PackageAction] {
        return packages.filter { (k, v) in v.isInstalling }
    }
    
    private func bindCancel() -> Disposable {
        return view.onCancelTapped.drive(onNext: { [weak self] in self?.view.cancel() })
    }
    
    private func bindDownload() -> Disposable {
        let client = PahkatClient()!
        
        return Observable.from(downloadablePackages().values).map { action -> Observable<(Package, PackageDownloadStatus)> in
            print("Downloading \(action.packageRecord.id)")
            
            return client.download(packageKey: action.packageRecord.id, target: action.target)
                .do(onNext: { [weak self] args in
                    print(args)
                    self?.view.setStatus(package: action.packageRecord.package, status: args.status)
                })
                .map { (action.packageRecord.package, $0.status) }
            }
            .merge(maxConcurrent: 3)
            .toArray()
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.view.startInstallation(packages: self.packages)
                },
                onError: { [weak self] in
                    self?.view.handle(error: $0)
                })
    }
        
    func start() -> Disposable {
        self.view.initializeDownloads(packages: downloadablePackages().map { $0.1.packageRecord.package })
        
        return CompositeDisposable.init(disposables: [
            self.bindDownload(),
            self.bindCancel()
        ])
    }
}
