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
    var packages: [UpdateTablePackage] = []
    
    required init(view: UpdateViewable) {
        self.view = view
    }
    
    private func bindSkipButton() -> Disposable {
        return view.onSkipButtonPressed.drive(onNext: { [weak self] in
            // TODO: handle skip properly
            self?.view.closeWindow()
        })
    }
    
    private func bindInstallButton() -> Disposable {
        return view.onInstallButtonPressed.drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            
            var map = [URL: PackageAction]()
            
            for item in self.packages {
                if !item.isEnabled {
                    continue
                }
                
                map[item.action.repository.url(for: item.package)] = item.action
            }
            
            self.view.installPackages(packages: map)
        })
    }
    
    private func bindLaterButton() -> Disposable {
        return view.onRemindButtonPressed.drive(onNext: { [weak self] in
            self?.view.closeWindow()
        })
    }
    
    private func bindPackageToggled() -> Disposable {
        return self.view.onPackageToggled.subscribe(onNext: { [weak self] package in
            guard let `self` = self else { return }
            guard let index = self.packages.index(where: { $0 == package }) else {
                return
            }
            
            self.packages[index].isEnabled = !self.packages[index].isEnabled
            
            self.view.setPackages(packages: self.packages)
        })
    }
    
    private func bindUpdateablePackages() -> Disposable {
        return AppContext.store.state.map { $0.repositories }
            .distinctUntilChanged({ (a, b) in a == b })
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] repos in
                guard let `self` = self else { return }
                
                var packageOutlines = [UpdateTablePackage]()
                
                // Get all the updateables
                for repo in repos {
                    let outlines: [UpdateTablePackage] = repo.statuses.compactMap {
                        if $0.1.status != PackageInstallStatus.requiresUpdate {
                            return nil
                        }
                        
                        
                        let package = repo.packages[$0.0]!
                        let key = repo.absoluteKey(for: package)
                        let record = PackageRecord(id: key, package: package)
                        
                        return UpdateTablePackage(package: package, action: PackageAction.install(repo, record, $0.1.target), isEnabled: true)
                    }
                    
                    packageOutlines.append(contentsOf: outlines)
                }
                
                let updatingPackages = packageOutlines.sorted()
                self.packages = updatingPackages
                self.view.setPackages(packages: updatingPackages)
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
