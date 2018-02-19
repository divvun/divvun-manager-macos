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
    
    private func download() -> Disposable {
        return Observable.from(packages)
            .map({ package in
                try AppContext.rpc.download(package, target: .user).map({(package, $0)})
            })
            .merge(maxConcurrent: 3).do(onNext: { [weak self] (package, status) in
                self?.view.setStatus(package: package, status: status)
            })
            .toArray().subscribe(
                onError: { [weak self] in
                    self?.view.handle(error: $0)},
                onCompleted: { [weak self] in
                    guard let `self` = self else { return }
                    self.view.startInstallation(packages: self.packages)
            })
    }
    
    func start() -> Disposable {
        return CompositeDisposable.init(disposables: [self.download()])
    }
}
