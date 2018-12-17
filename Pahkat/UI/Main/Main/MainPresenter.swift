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
        let key = OutlineGroup(id: package.category, value: value)
        
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
            let key = OutlineGroup(id: language, value: ISO639.get(tag: language)?.autonymOrName ?? language)
            if !data.keys.contains(key) {
                data[key] = []
            }
            
            data[key]!.append(OutlinePackage(package: package, action: nil))
        }
    }
    
    return data
}

class MainPresenter {
    private let bag = DisposeBag()
    private unowned let view: MainViewable
    private var data: MainOutlineMap = Map()
    private let client = AppContext.client
    private var selectedPackages = [AbsolutePackageKey: PackageAction]()
    
    init(view: MainViewable) {
        self.view = view
    }
    
    private func updateFilters(key: OutlineRepository) {
        let repo = key.repo
        
        switch key.filter {
        case .category:
            data[key] = categoryFilter(repo: repo)
        case .language:
            data[key] = languageFilter(repo: repo)
        }
    }
    
    private func updateData(with repositories: [RepositoryIndex]) {
        data = MainOutlineMap()
        
        repositories.forEach { repo in
            let key = OutlineRepository(filter: repo.meta.primaryFilter, repo: repo)
            self.updateFilters(key: key)
        }
    }
    
    private func bindUpdatePackageList() -> Disposable {
        return AppContext.store.state
            .map { $0.repositories }
//            .distinctUntilChanged({ (a, b) in a == b })
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] repos in
                guard let `self` = self else { return }
                self.updateData(with: repos)
                self.view.updateProgressIndicator(isEnabled: false)
                self.view.setRepositories(data: self.data)
                
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
    
    private func bindSettingsButton() -> Disposable {
        return view.onSettingsTapped.drive(onNext: { [weak self] in
            self?.view.showSettings()
        })
    }
    
    private func bindPrimaryButton() -> Disposable {
        return view.onPrimaryButtonPressed.drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            if self.selectedPackages.values.contains(where: { $0.target == .system }) {
                let recv = PahkatAdminReceiver()
                recv.isLaunchServiceInstalled
                    .observeOn(MainScheduler.instance)
                    .timeout(1.0, scheduler: MainScheduler.instance)
                    .catchErrorJustReturn(false)
                    .subscribe(onSuccess: { isInstalled in
                        print("Service is installed? \(isInstalled)")
                        
                        if isInstalled {
                            self.view.showDownloadView(with: self.selectedPackages)
                            return
                        }
                        
                        do {
                            _ = try recv.installLaunchService(errorCallback: { error in
                                DispatchQueue.main.async {
                                    self.view.handle(error: error)
                                }
                            })
                            self.view.showDownloadView(with: self.selectedPackages)
                        } catch  {
                            self.view.handle(error: error)
                            return
                        }
                    })
                    .disposed(by: self.bag)
            } else {
                self.view.showDownloadView(with: self.selectedPackages)
            }
        })
    }
    
    enum PackageStateOption {
        case toggle
        case set(PackageAction?)
    }
    
    private func setPackageState(to option: PackageStateOption, package: Package, repo: OutlineRepository) {
        guard let packageMap = self.data[repo] else { return }
        
        for item in packageMap {
            guard case let .macOsInstaller(installer) = package.installer else {
                continue
            }
            
            if let outlinePackage = item.1.first(where: { $0.package == package }), let info = repo.repo.status(forPackage: package) {
                let packageKey = repo.repo.absoluteKey(for: package)
                let packageRecord = PackageRecord.init(id: packageKey, package: package)
                switch option {
                case .toggle:
                    if outlinePackage.action == nil {
                        switch info.status {
                        case .upToDate:
                            outlinePackage.action = PackageAction(action: .uninstall, packageRecord: packageRecord, target: info.target)
                        default:
                            let target = installer.targets[0].rawValue == "system" ? InstallerTarget.system : InstallerTarget.user
                            outlinePackage.action = PackageAction(action: .install, packageRecord: packageRecord, target: target)
                        }
                    } else {
                        outlinePackage.action = nil
                    }
                    
                    if let action = outlinePackage.action {
                        self.selectedPackages[action.packageRecord.id] = action
                    } else {
                        self.selectedPackages[packageRecord.id] = nil
                    }
                case let .set(action):
                    outlinePackage.action = action
                    if let action = action {
                        self.selectedPackages[action.packageRecord.id] = action
                    }
                }
            }
        }
    }
    
    private func bindUpdatePackagesOnLoad() -> Disposable {
        // Always update the repos on load.
        return AppContext.settings.state.map { $0.repositories }
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .flatMapLatest { [weak self] (configs: [RepoConfig]) -> Observable<[RepositoryIndex]> in
                guard let `self` = self else { return Observable.empty() }
                
                self.view.updateSettingsButton(isEnabled: false)
                self.view.updateProgressIndicator(isEnabled: true)
                self.client.refreshRepos()
                
                let repos: [RepositoryIndex] = self.client.repos()
                
                if repos.count != configs.count {
                    // TODO: Localizable strings
                    
                    var configSet = Set(configs.map { $0.url })
                    configSet.subtract(Set(repos.map { $0.meta.base }))
                    
                    var failingReposString = ""
                    
                    for failingURL in configSet {
                        print("Could not load URL \(failingURL)\n")
                        failingReposString.append("Could not load URL \(failingURL)\n")
                    }
                    
                    let alert = NSAlert()
                    alert.messageText = "Could not load all repos"
                    alert.informativeText = failingReposString
                    alert.runModal()
                }
                
                return Observable.just(repos)
            }
            .subscribe(onNext: { [weak self] repos in
                print("Refreshed repos in main view.")
                self?.view.updateSettingsButton(isEnabled: true)
                AppContext.store.dispatch(event: AppEvent.setRepositories(repos))
                self?.view.updateProgressIndicator(isEnabled: false)
            }, onError: { [weak self] error in
                self?.view.handle(error: error)
                self?.view.updateSettingsButton(isEnabled: true)
                self?.view.updateProgressIndicator(isEnabled: false)
            })
    }
    
    private func bindContextMenuEvents() -> Disposable {
        return view.onPackageEvent.subscribe(onNext: { [weak self] event in
            guard let `self` = self else { return }
            
            switch event {
            case let .setPackageAction(action):
                
                guard let outlineRepo = self.data.keys.first(where: { $0.repo.packages.values.contains(action.packageRecord.package) }) else {
                    return
                }
                self.setPackageState(to: .set(action), package: action.packageRecord.package, repo: outlineRepo)
                self.updatePrimaryButton()
                self.view.refreshRepositories()
            case let .changeFilter(repo, filter):
                repo.filter = filter
                self.updateFilters(key: repo)
                for action in self.selectedPackages.values {
                    self.setPackageState(to: .set(action), package: action.packageRecord.package, repo: repo)
                }
                self.view.setRepositories(data: self.data)
            default:
                return
            }
        })
    }
    
    private func bindPackageToggleEvent() -> Disposable {
        return view.onPackageEvent
            .flatMapLatest { [weak self] (event: OutlineEvent) -> Observable<(OutlineRepository, [Package])> in
                guard let `self` = self else { return Observable.empty() }
                
                switch event {
                case let .togglePackage(repo, package):
                    return Observable.just((repo, [package]))
                case let .toggleGroup(repo, group):
                    let packages = self.data[repo]![group]!
                    let toggleIds = Set(self.selectedPackages.keys).intersection(packages.map { repo.repo.absoluteKey(for: $0.package) })
                    let x = toggleIds.count > 0
                        ? toggleIds.map { url in packages.first(where: { url == repo.repo.absoluteKey(for: $0.package) })!.package }
                        : packages.map { $0.package }
                    return Observable.just((repo, x))
                default:
                    return Observable.empty()
                }
            }
            .subscribe(onNext: { [weak self] tuple in
                guard let `self` = self else { return }
                
                let repo = tuple.0
                let packages = tuple.1
                
                for package in packages {
                    self.setPackageState(to: .toggle, package: package, repo: repo)
                }
                
                self.updatePrimaryButton()
                self.view.refreshRepositories()
            })
        
    }
    
    func start() -> Disposable {
        return CompositeDisposable(disposables: [
            bindSettingsButton(),
            bindUpdatePackageList(),
            bindPackageToggleEvent(),
            bindPrimaryButton(),
            bindContextMenuEvents(),
            bindUpdatePackagesOnLoad()
        ])
    }
}
