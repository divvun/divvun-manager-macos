//
//  InstallPresenter.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-19.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class InstallPresenter {
    private unowned var view: InstallViewable
    private let packages: [Package]
    
    init(view: InstallViewable, packages: [Package]) {
        self.view = view
        self.packages = packages
        
        self.view.set(totalPackages: packages.count)
    }
    
    func installTest() -> Single<PackageInstallStatus> {
        // TODO: subprocess
        return Single.just(PackageInstallStatus.notInstalled)
//            .delay(2.0, scheduler: MainScheduler.instance)
    }
    
    func start() -> Disposable {
        // TODO: check the starting response to make sure we're in a sane state
        return try! Observable.concat(packages.map({ [weak self] package -> Observable<PackageInstallStatus> in
//            try AppContext.rpc.install(package, target: .user)
            installTest()
                .do(
                    onSuccess: ({ _ in
                        print("I did a success")
                        self?.view.setEnding(package: package)
                    }),
                    onSubscribe: {
                        print ("I did a subscribe")
                        self?.view.setStarting(package: package)
                    }
                ).asObservable()
//                .observeOn(MainScheduler.instance).subscribeOn(MainScheduler.instance)
        }))
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
        .toArray()
        .subscribe(onNext: { _ in
            AppContext.windows.set(CompletionViewController(), for: MainWindowController.self)
        })
    }
}
