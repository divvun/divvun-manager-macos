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
    
    
    
    func start() -> Disposable {
        return try! Observable.concat(packages.map({ [weak self] package in
            try AppContext.rpc.install(package, target: .user).do(onSuccess: ({ _ in  self?.view.setEnding(package: package)}), onSubscribe: {self?.view.setStarting(package: package)}).asObservable()
        })).subscribe()
    }
}
