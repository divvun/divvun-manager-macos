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
    let packages: [Package]
    
    required init(view: DownloadViewable, packages: [Package]) {
        self.view = view
        self.packages = packages
    }
    
    func downloadTest() -> Observable<PackageDownloadStatus> {
        // TODO: subprocess
        let foo: [PackageDownloadStatus] = [.notStarted,
                                            .starting,
                                            .progress(downloaded: 0, total: 100),
                                            .progress(downloaded: 50, total: 100),
                                            .progress(downloaded: 100, total: 100),
                                            .completed]
        return Observable.interval(1.0, scheduler: MainScheduler.instance)
            .map {
                foo[$0]
            }.take(foo.count)
    }
    
    private func download() -> Disposable {
        
//        return try! AppContext.rpc.download(packages[0], target: .user).do(onNext: { [weak self] status in
//            self?.view.setStatus(package: self!.packages[0], status: status)
//        }).subscribe()
        
        return Observable.from(try! packages.map { package in
                try AppContext.rpc.download(package, target: .user)
                    .do(onNext: { [weak self] status in
                        self?.view.setStatus(package: package, status: status)
                    }).takeWhile({
                        if case .completed = $0 { return false } else { return true }
                    })
            })
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
        return CompositeDisposable.init(disposables: [self.download()])
    }
}
