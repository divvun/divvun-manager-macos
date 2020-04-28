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


typealias PackageOutlineMap = Map<OutlineGroup, SortedSet<OutlinePackage>>
typealias MainOutlineMap = Map<OutlineRepository, PackageOutlineMap>

fileprivate func categoryFilter(outlineRepo: OutlineRepository) -> PackageOutlineMap {
    var data = PackageOutlineMap()
    let repo = outlineRepo.repo

    repo.descriptors.values.forEach { (descriptor: Descriptor) in
        guard let release = descriptor.release.first else { return }
        guard let target = release.macosTarget else {
            // this package doesn't have a macos target
            return
        }

        let categoryId = descriptor.tags.first(where: { $0.starts(with: "cat:") }) ?? "cat:unknown"
        let category = categoryId // TODO: make native, human readable
        let key = OutlineGroup(id: categoryId, value: category, repo: outlineRepo)

        if !data.keys.contains(key) {
            data[key] = []
        }

        let outlinePackage = OutlinePackage(package: descriptor,
                                            release: release,
                                            target: target,
                                            status: (PackageStatus.notInstalled, SystemTarget.system), // TODO: get this from reality
                                            group: key,
                                            repo: outlineRepo,
                                            selection: nil)
        data[key]!.insert(outlinePackage)
    }

    return data
}

fileprivate func languageFilter(outlineRepo: OutlineRepository) -> PackageOutlineMap {
    var data = PackageOutlineMap()
    let repo = outlineRepo.repo

    repo.descriptors.values.forEach { descriptor in
        guard let release = descriptor.release.first else { return }
        guard let target = release.macosTarget else {
            // this package doesn't have a macos target
            return
        }
        
        var languages = descriptor.tags
            .filter { $0.starts(with: "lang:") }
            .map { String($0.split(separator: ":")[1]) }
        
        if languages.isEmpty {
            languages.append("zxx")
        }

        languages.forEach { language in
            let value: String
            if language == "zxx" {
                value = "—"
            } else {
                value = ISO639.get(tag: language)?.autonymOrName ?? language
            }

            let key = OutlineGroup(id: language, value: value, repo: outlineRepo)
            if !data.keys.contains(key) {
                data[key] = []
            }

            let outlinePackage = OutlinePackage(package: descriptor,
                                                release: release,
                                                target: target,
                                                status: (PackageStatus.notInstalled, SystemTarget.system), // TODO: get this from reality
                                                group: key,
                                                repo: outlineRepo,
                                                selection: nil)
            data[key]!.insert(outlinePackage)
        }
    }

    return data
}

class MainPresenter {
    private let bag = DisposeBag()
    private unowned let view: MainViewable
    private var data: MainOutlineMap = Map()
    private var selectedPackages = [PackageKey: SelectedPackage]()
    
    init(view: MainViewable) {
        self.view = view
    }
    
    private func updateFilters(key: OutlineRepository) {
        switch key.filter {
        case .category:
            data[key] = categoryFilter(outlineRepo: key)
        case .language:
            data[key] = languageFilter(outlineRepo: key)
        }
    }
    
    private func updateData(with repositories: [LoadedRepository]) {
        data = MainOutlineMap()
        
        repositories.forEach { repo in
            print(repo)
            let filter = OutlineFilter.language // TODO: get this from the repo?
            let key = OutlineRepository(filter: filter, repo: repo)
            self.updateFilters(key: key)
        }
    }
    
    private func bindUpdatePackageList() -> Disposable {
//        notificationSubject
//            .filter { $0 == "new repo shit bro" } // Observable<String>
//            .map { _ in // Observable<String> -> Single<[LoadedRepository]>
//                AppContext.packageStore.repoIndexes() // Observable<Single<[LoadedRepository]>>
//            }
//            .switchLatest() // Observable<T<[LoadedRepository]>> -> T -> Observable<[LoadedRepository]>
        AppContext.packageStore.repoIndexes()
            .asObservable()
            .distinctUntilChanged({ (a, b) in a == b }) //Observable<[LoadedRepository]>
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

            let actions = self.selectedPackages.values.map { (package: SelectedPackage) in
                return PackageAction(key: package.key, action: package.action, target: package.target)
            }
            AppContext.currentActions = actions

            let (cancelable, stream) = AppContext.packageStore.processTransaction(actions: actions)
            AppContext.cancelTransactionCallback = cancelable

//            DispatchQueue.main.async {
                let disposable = stream.subscribe { event in
                    print(event)
                    sleep(1)
                    switch event {
                    case let .next(item):
                        AppContext.currentTransaction.onNext(item)
                    default:
                        break
                    }
                }
                disposable.disposed(by: AppContext.disposeBag)
//                AppContext.windows.set(DownloadViewController(actions: actions), for: MainWindowController.self)
//            }
//            self.view.showDownloadView(with: self.selectedPackages)
        })
    }
    
    enum PackageStateOption {
        case toggle
        case set(SelectedPackage?)
    }
    
    private func setPackageState(to option: PackageStateOption, package: Descriptor, repo: OutlineRepository) {
        guard let packageMap: PackageOutlineMap = self.data[repo] else { return }

        for item in packageMap {
            if let outlinePackage: OutlinePackage = item.1.first(where: { $0.package == package }) {
                let packageKey = repo.repo.packageKey(for: package)
                switch option {
                case .toggle:
                    if outlinePackage.selection == nil {
                        let (status, target) = outlinePackage.status
                        switch status {
                        case .upToDate:
                            outlinePackage.selection = SelectedPackage(
                                key: packageKey,
                                package: package,
                                action: .uninstall,
                                target: target)
                        default:
                            outlinePackage.selection = SelectedPackage(
                                key: packageKey,
                                package: package,
                                action: .install,
                                target: target)
                        }
                    } else {
                        outlinePackage.selection = nil
                    }

                    if let action = outlinePackage.selection {
                        self.selectedPackages[action.key] = action
                    } else {
                        self.selectedPackages[packageKey] = nil
                    }
                case let .set(action):
                    outlinePackage.selection = action
                    if let action = action {

                        self.selectedPackages[action.key] = action
                    }
                }
            }
        }
    }
    
    private func bindContextMenuEvents() -> Disposable {
        return view.onPackageEvent
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                guard let `self` = self else { return }

                switch event {
                case let .setPackageSelection(action):
                    guard let outlineRepo = self.data.keys.first(where: { $0.repo.descriptors.values.contains(action.package) }) else {
                        return
                    }
                    self.setPackageState(to: .set(action), package: action.package, repo: outlineRepo)
                    self.updatePrimaryButton()
                    self.view.refreshRepositories()
                case let .changeFilter(repo, filter):
                    repo.filter = filter
                    self.updateFilters(key: repo)
                    for action in self.selectedPackages.values {
                        self.setPackageState(to: .set(action), package: action.package, repo: repo)
                    }
                    self.view.setRepositories(data: self.data)
                default:
                    return
                }
            })
    }
    
    private func bindPackageToggleEvent() -> Disposable {
        return view.onPackageEvent
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .flatMapLatest { [weak self] (event: OutlineEvent) -> Observable<(OutlineRepository, [Descriptor])> in
                guard let `self` = self else { return Observable.empty() }

                switch event {
                case let .togglePackage(item):
                    return Observable.just((item.repo, [item.package]))
                case let .toggleGroup(item):
                    let packages = self.data[item.repo]![item]!
                    let toggleIds = Set(self.selectedPackages.keys).intersection(packages.map { item.repo.repo.packageKey(for: $0.package) })
                    let x = toggleIds.count > 0
                        ? toggleIds.map { url in packages.first(where: { url == item.repo.repo.packageKey(for: $0.package) })!.package }
                        : packages.map { $0.package }
                    return Observable.just((item.repo, x))
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
        ])
    }
}

