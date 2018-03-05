//
//  UpdatePresenter.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class UpdatePresenter {
    private unowned let view: UpdateViewable
    
    required init(view: UpdateViewable) {
        self.view = view
    }
    
    private func bindSkipButton() -> Disposable {
        return view.onSkipButtonPressed.drive(onNext: {
            
        })
    }
    
    private func bindInstallButton() -> Disposable {
        return view.onInstallButtonPressed.drive(onNext: {
            
        })
    }
    
    private func bindLaterButton() -> Disposable {
        return view.onRemindButtonPressed.drive(onNext: {
            
        })
    }
    
    private func bindPackageToggled() -> Disposable {
        return self.view.onPackageToggled.subscribe(onNext: { [weak self] package in
            self?.view.updateSelectedPackages(packages: [])
        })
    }
    
    private func bindUpdateablePackages() -> Disposable {
        return AppContext.store.state.map { $0.repositories }
            .distinctUntilChanged({ (a, b) in a == b })
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] repos in
                guard let `self` = self else { return }
                
                var packages = [RepositoryIndex: [Package]]()
                
                // Get all the updateables
                for repo in repos {
                    let packageIds = repo.statuses.flatMap { return $0.1.status == PackageInstallStatus.requiresUpdate ? $0.0 : nil }
                    packages[repo] = packageIds.map { repo.packages[$0]! }
                }
                
                let updatingPackages = packages.values.joined().sorted()
                self.view.setPackages(packages: updatingPackages)
                self.view.updateSelectedPackages(packages: updatingPackages)
            })
    }
    
    func start() -> Disposable {
        return CompositeDisposable(disposables: [
            bindSkipButton(),
            bindInstallButton(),
            bindLaterButton(),
            bindUpdateablePackages(),
            bindPackageToggled()
        ])
    }
}
