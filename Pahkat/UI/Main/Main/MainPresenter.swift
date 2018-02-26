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

enum PackageAction: Hashable {
    case install(Package)
    case uninstall(Package)
    
    static func ==(lhs: PackageAction, rhs: PackageAction) -> Bool {
        switch (lhs, rhs) {
        case let (.install(a), .install(b)):
            return a == b
        case let (.uninstall(a), .uninstall(b)):
            return a == b
        default:
            return false
        }
    }
    
    var isInstalling: Bool {
        if case .install = self { return true } else { return false }
    }
    
    var isUninstalling: Bool {
        if case .uninstall = self { return true } else { return false }
    }
    
    var hashValue: Int {
        return self.package.hashValue
    }
    
    var package: Package {
        switch self {
        case let .install(package):
            return package
        case let .uninstall(package):
            return package
        }
    }
    
    var description: String {
        switch self {
        case .install(_):
            return Strings.install
        case .uninstall(_):
            return Strings.uninstall
        }
    }
}

class MainPresenter {
    private unowned var view: MainViewable
    private var repo: RepositoryIndex? = nil
    private var statuses = [String: PackageInstallStatus]()
    private var selectedPackages = [String: PackageAction]()
    
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
                guard let `self` = self else { return }
                // TODO: do what is needed to cause the outline view to update.
                self.statuses = statuses
                self.repo = repo
                self.view.setRepository(repo: repo, statuses: statuses)
//                print(repo.meta)
            }, onError: { [weak self] in self?.view.handle(error: $0) })
    }
    
    private func bindPackageToggled() -> Disposable {
        return view.onPackagesToggled.subscribe(onNext: { [weak self] packages in
            guard let `self` = self else { return }
            
            for package in packages {
                if let _ = self.selectedPackages[package.id] {
                    self.selectedPackages.removeValue(forKey: package.id)
                } else {
                    guard let status = self.statuses[package.id] else { fatalError("No status found for package \(package.id)") }
                    
                    switch status {
                    case .upToDate:
                        self.selectedPackages[package.id] = .uninstall(package)
                    default:
                        self.selectedPackages[package.id] = .install(package)
                    }
                }
            }
            
            self.view.updateSelectedPackages(packages: self.selectedPackages)
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
        })
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
            window.contentWindow.set(viewController: DownloadViewController(packages: self.selectedPackages))
        })
    }
    
    func start() -> Disposable {        
        print("WE ARE STARTING")
        
        return CompositeDisposable(disposables: [
            bindSettingsButton(),
            bindUpdatePackageList(),
            bindPackageToggled(),
            bindPrimaryButton()
        ])
    }
    
    deinit {
        print("PRESENTER DEINIT")
    }
}
