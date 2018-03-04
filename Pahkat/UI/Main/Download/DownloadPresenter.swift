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
    let packages: [URL: PackageAction]
    
    required init(view: DownloadViewable, packages: [URL: PackageAction]) {
        self.view = view
        self.packages = packages
    }
    
    func downloadTest() -> Observable<PackageDownloadStatus> {
        // TODO: subprocess
        let max: UInt64 = 31290892
        
        let foo: [PackageDownloadStatus] = [.notStarted,
                                            .starting,
                                            .progress(downloaded: 0, total: max),
                                            .progress(downloaded: max / 5 * 1, total: max),
                                            .progress(downloaded: max / 5 * 2, total: max),
                                            .progress(downloaded: max / 5 * 3, total: max),
                                            .progress(downloaded: max / 5 * 4, total: max),
                                            .progress(downloaded: max, total: max),
                                            .completed]
        return Observable.interval(0.25, scheduler: MainScheduler.instance)
            .map {
                foo[$0]
            }.take(foo.count)
    }
    
    func downloadablePackages() -> [(Package, RepositoryIndex, MacOsInstaller.Targets)] {
        return packages.values
            .filter { $0.isInstalling }
            .map { ($0.package, $0.repository, $0.target) }
    }
    
    private func bindCancel() -> Disposable {
        return view.onCancelTapped.drive(onNext: { [weak self] in self?.view.cancel() })
    }
    
    private func bindDownload() -> Disposable {
        
//        return try! AppContext.rpc.download(packages[0], target: .user).do(onNext: { [weak self] status in
//            self?.view.setStatus(package: self!.packages[0], status: status)
//        }).subscribe()
        
        return Observable.from(downloadablePackages())
            .map { (package: Package, repo: RepositoryIndex, target: MacOsInstaller.Targets) -> Observable<(Package, PackageDownloadStatus)> in
                try AppContext.rpc.download(package, repo: repo, target: target)
                    .do(onNext: { [weak self] status in
                        self?.view.setStatus(package: package, status: status)
                    }).takeWhile({
                        if case .completed = $0 { return false } else { return true }
                    }).map { (package, $0) }
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
        
//        return Observable.from(try! packages.map { package in
//
//            })
//            .merge(maxConcurrent: 3)
//            .toArray()
//            .observeOn(MainScheduler.instance)
//            .subscribeOn(MainScheduler.instance)
//            .subscribe(
//                onNext: { [weak self] _ in
//                    guard let `self` = self else { return }
//                    self.view.startInstallation(packages: self.packages)
//                },
//                onError: { [weak self] in
//                    self?.view.handle(error: $0)
//                })
    }
    
    func start() -> Disposable {
        self.view.initializeDownloads(packages: downloadablePackages().map { $0.0 })
        
        return CompositeDisposable.init(disposables: [
            self.bindDownload(),
            self.bindCancel()
        ])
    }
}
