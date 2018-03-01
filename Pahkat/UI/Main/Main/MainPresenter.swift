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
import BTree


typealias PackageOutlineMap = Map<OutlineGroup, [OutlinePackage]>
typealias MainOutlineMap = Map<OutlineRepository, PackageOutlineMap>

fileprivate func categoryFilter(repo: RepositoryIndex) -> PackageOutlineMap {
    var data = PackageOutlineMap()
    
    repo.packages.values.forEach { package in
        let value = repo.meta.nativeCategory(for: package.category)
        let key = OutlineGroup(id: package.category, value: value, filter: .category)
        
        if !data.keys.contains(key) {
            data[key] = []
        }
        
        data[key]!.append(OutlinePackage(package: package, action: nil))
    }
    
    return data
}

fileprivate func languageFilter(repo: RepositoryIndex) -> PackageOutlineMap {
    var data = PackageOutlineMap()
    
    repo.packages.values.forEach { package in
        package.languages.forEach { language in
            let key = OutlineGroup(id: language, value: ISO639.get(tag: language)?.autonymOrName ?? language, filter: .language)
            if !data.keys.contains(key) {
                data[key] = []
            }
            
            data[key]!.append(OutlinePackage(package: package, action: nil))
        }
    }
    
    return data
}

class MainPresenter {
    private unowned let view: MainViewable
    private var data: MainOutlineMap = Map()
    private var selectedPackages = [URL: PackageAction]()
    
    
    init(view: MainViewable) {
        self.view = view
    }
    
//    private func bindPrimaryButtonLabel() -> Disposable {
//
//    }
    
    private func updateData(with repositories: [RepositoryIndex]) {
        data = MainOutlineMap()
        
        repositories.forEach { repo in
            let key = OutlineRepository(filter: repo.meta.primaryFilter, repo: repo)
            
            switch repo.meta.primaryFilter {
            case .category:
                data[key] = categoryFilter(repo: repo)
            case .language:
                data[key] = languageFilter(repo: repo)
            }
        }
    }
    
    private func bindUpdatePackageList() -> Disposable {
        return AppContext.store.state
            .map { $0.repositories }
            .distinctUntilChanged({ (a, b) in a == b })
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] repos in
                guard let `self` = self else { return }
                self.updateData(with: repos)
                self.view.setRepositories(data: self.data)
//                print(repo.meta)
            }, onError: { [weak self] in self?.view.handle(error: $0) })
    }
    
    private func updatePrimaryButton() {
        let packageCount = String(self.selectedPackages.values.count)
        
        let hasInstalls = self.selectedPackages.values.first(where: { $0.isInstalling }) != nil
        let hasUninstalls = self.selectedPackages.values.first(where: { $0.isUninstalling }) != nil
        
        var isEnabled: Bool = true
        let label: String
        
        if hasInstalls && hasUninstalls {
            label = Strings.installUninstallNPackages(count: packageCount)
        } else if hasInstalls {
            label = Strings.installNPackages(count: packageCount)
        } else if hasUninstalls {
            label = Strings.uninstallNPackages(count: packageCount)
        } else {
            isEnabled = false
            label = Strings.noPackagesSelected
        }
        
        self.view.updatePrimaryButton(isEnabled: isEnabled, label: label)
    }
//
//    private func bindGroupToggled() -> Disposable {
//
//    }
//
    private func bindSettingsButton() -> Disposable {
        return view.onSettingsTapped.drive(onNext: { [weak self] in
            self?.view.showSettings()
        })
    }
    
    private func bindPrimaryButton() -> Disposable {
        return view.onPrimaryButtonPressed.drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            let window = AppContext.windows.get(MainWindowController.self)
//            window.contentWindow.set(viewController: DownloadViewController(packages: self.selectedPackages))
        })
    }
    
    
    private func bindPackageToggleEvent() -> Disposable {
        return view.onPackageEvent
            .flatMapLatest { [weak self] (event: OutlineEvent) -> Observable<(RepositoryIndex, [Package])> in
                guard let `self` = self else { return Observable.empty() }
                
                switch event {
                case let .togglePackage(repo, package):
                    return Observable.just((repo, [package]))
                case let .toggleGroup(repo, group):
                    let packages = self.data[repo]![group]!
                    let toggleIds = Set(self.selectedPackages.keys).intersection(packages.map { repo.repo.url(for: $0.package) })
                    let x = toggleIds.count > 0 ? toggleIds.map { url in packages.first(where: { url == repo.repo.url(for: $0.package) })!.package } : packages.map { $0.package }
                    return Observable.just((repo.repo, x))
                default:
                    return Observable.empty()
                }
            }
            .subscribe(onNext: { [weak self] tuple in
                guard let `self` = self else { return }
                
                let repo = tuple.0
                let packages = tuple.1
                
                guard let (_, packageMap) = self.data.first(where: { $0.0.repo == repo }) else { return }
                
                for package in packages {
                    for item in packageMap {
                        guard case let .macOsInstaller(installer) = package.installer else {
                            continue
                        }
                        
                        if let toggledPackage = item.1.first(where: { $0.package == package }), let status = repo.status(for: package) {
                            if toggledPackage.action == nil {
                                switch status.status {
                                case .upToDate:
                                    toggledPackage.action = PackageAction.uninstall(repo, package, installer.targets[0])
                                default:
                                    toggledPackage.action = PackageAction.install(repo, package, installer.targets[0])
                                }
                            } else {
                                toggledPackage.action = nil
                            }
                            self.selectedPackages[repo.url(for: package)] = toggledPackage.action
                        }
                    }
                }
                
                self.updatePrimaryButton()
                
//                self.view.setRepositories(data: self.data)
                self.view.refreshRepositories()
            })
        
    }
    
    func start() -> Disposable {        
        print("WE ARE STARTING")
        
        return CompositeDisposable(disposables: [
            bindSettingsButton(),
            bindUpdatePackageList(),
            bindPackageToggleEvent(),
            bindPrimaryButton()
        ])
    }
    
    deinit {
        print("PRESENTER DEINIT")
    }
}
