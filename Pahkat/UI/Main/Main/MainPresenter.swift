//
//  MainPresenter.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class MainPresenter {
    private unowned var view: MainViewable
    private var repo: RepositoryIndex? = nil
    private var selectedPackages = Set<Package>()
    
    init(view: MainViewable) {
        self.view = view
    }
    
//    private func bindPrimaryButtonLabel() -> Disposable {
//
//    }
    
    private func bindUpdatePackageList() -> Disposable {
        return AppContext.store.state
            .filter { $0.repository != nil }
            .map { $0.repository! }
            .distinctUntilChanged()
            .flatMapLatest { (repo: RepositoryIndex) -> Observable<(RepositoryIndex, [String: PackageInstallStatus])> in
                let statuses = repo.packages.values.flatMap { package in
                    try? AppContext.rpc.status(of: package, target: .user)
                        .map { (package.id, $0) }
                        .asObservable()
                }
                
                return Observable.merge(statuses)
                    .toArray()
                    .map({ (pairs: [(String, PackageInstallStatus)]) -> (RepositoryIndex, [String: PackageInstallStatus]) in
                        var out = [String: PackageInstallStatus]()
                        pairs.forEach { out[$0.0] = $0.1 }
                        return (repo, out)
                    })
            }
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (repo, statuses) in
                // TODO: do what is needed to cause the outline view to update.
                self?.repo = repo
                self?.view.setRepository(repo: repo, statuses: statuses)
//                print(repo.meta)
            }, onError: { [weak self] in self?.view.handle(error: $0) })
    }
    
    private func bindPackageToggled() -> Disposable {
        return view.onPackagesToggled.subscribe(onNext: { [weak self] packages in
            guard let `self` = self else { return }
            
            for package in packages {
                if self.selectedPackages.contains(package) {
                    self.selectedPackages.remove(package)
                } else {
                    self.selectedPackages.insert(package)
                }
            }
            
            self.view.updateSelectedPackages(packages: self.selectedPackages)
//            print($0.name["en"])
            
            
        })
    }
//
//    private func bindGroupToggled() -> Disposable {
//
//    }
//
    private func bindPrimaryButton() -> Disposable {
        return view.onPrimaryButtonPressed.drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            let window = AppContext.windows.get(MainWindowController.self)
            window.contentWindow.set(viewController: DownloadViewController(packages: Array(self.selectedPackages)))
        })
    }
    
    func start() -> Disposable {
        //guard let view = view else { return Disposables.create() }
        
        view.update(title: Strings.loading)
        
        return CompositeDisposable(disposables: [
//            bindPrimaryButtonLabel(),
            bindUpdatePackageList(),
            bindPackageToggled(),
//            bindGroupToggled(),
            bindPrimaryButton()
        ])
        
//        return view.onPrimaryButtonPressed.drive(onNext: {
//
//        }, onCompleted: nil, onDisposed: nil)
    }
}
