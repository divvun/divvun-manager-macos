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
    private let packages: [String: PackageAction]
    
    init(view: InstallViewable, packages: [String: PackageAction]) {
        self.view = view
        self.packages = packages
    }
    
    func installTest() -> Single<PackageInstallStatus> {
        // TODO: subprocess
        return Single.just(PackageInstallStatus.notInstalled)
//            .delay(2.0, scheduler: MainScheduler.instance)
    }
    
    func start() -> Disposable {
        self.view.set(totalPackages: packages.count)
        
        // TODO: check the starting response to make sure we're in a sane state
        return try! Observable.concat(packages.values.map({ [weak self] action -> Observable<PackageInstallStatus> in
//            try AppContext.rpc.install(package, target: .user)
            installTest()
                .do(
                    onSuccess: ({ _ in
                        print("I did a success")
                        self?.view.setEnding(action: action)
                    }),
                    onSubscribe: {
                        print ("I did a subscribe")
                        self?.view.setStarting(action: action)
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
