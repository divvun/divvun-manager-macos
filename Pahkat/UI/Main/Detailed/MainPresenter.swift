import Cocoa
import Foundation
import RxSwift
import RxCocoa
import RxBlocking


typealias PackageOutlineMap = Map<OutlineGroup, SortedSet<OutlinePackage>>
typealias MainOutlineMap = Map<OutlineRepository, PackageOutlineMap>

func sortByLanguage(outlineRepo: OutlineRepository) -> Single<PackageOutlineMap> {
    return sortByTagPrefix(outlineRepo: outlineRepo, prefix: "lang:", mutator: {
        if let tag = ISO639.get(tag: $0) {
            return tag.autonymOrName
        }

        return $0
    })
}

func sortByCategory(outlineRepo: OutlineRepository) -> Single<PackageOutlineMap> {
    let strings = AppContext.packageStore.strings(languageTag: "en")

    return strings.flatMap { s -> Single<PackageOutlineMap> in
        return sortByTagPrefix(outlineRepo: outlineRepo, prefix: "cat:", mutator: { x in
            guard let str = s[outlineRepo.repo.index.url] else { return x }
            guard let t = str.tags[x] else { return x }
            return t
        })
    }
}

func sortByTagPrefix(outlineRepo: OutlineRepository, prefix: String, mutator: @escaping (String) -> String) -> Single<PackageOutlineMap> {
    let repo = outlineRepo.repo

    let filteredDescriptors = repo.descriptors.values.filter { descriptor in
        guard let release = descriptor.release.first else { return false }
        guard release.macosTarget != nil else {
            // this package doesn't have a macos target
            return false
        }
        return true
    }

    let statuses = Observable.from(filteredDescriptors.map { repo.packageKey(for: $0) })
        .flatMap { key in AppContext.packageStore.status(packageKey: key).map { (key.id, $0) } }
        .toArray()
        .map {
            $0.reduce(into: [String: (PackageStatus, SystemTarget)]()) { (acc, cur) in
                acc[cur.0] = cur.1
            }
        }

    return statuses.map { statuses -> PackageOutlineMap in
        var data = Map<OutlineGroup, SortedSet<OutlinePackage>>()

        for (key, status) in statuses {
            guard let descriptor = repo.descriptors[key] else { continue }
            let tags = descriptor.tags.filter { $0.starts(with: prefix) }

            if tags.isEmpty {
                continue
            }

            for tag in tags {
                let group = OutlineGroup(id: tag, value: mutator(tag), repo: outlineRepo)

                if !data.keys.contains(group) {
                    data[group] = []
                }

                guard let release = descriptor.release.first else { continue }
                guard let target = release.macosTarget else { continue }

                let outlinePackage = OutlinePackage(package: descriptor,
                                                    release: release,
                                                    target: target,
                                                    status: status,
                                                    group: group,
                                                    repo: outlineRepo,
                                                    selection: nil)
                data[group]!.insert(outlinePackage)
            }

        }

        return data
    }
}

class MainPresenter {
    private let bag = DisposeBag()
    private unowned let view: MainViewable
    private var data: MainOutlineMap = Map()
    private var selectedPackages = [PackageKey: SelectedPackage]()

    init(view: MainViewable) {
        self.view = view
    }
    
    private func updateFilters(key: OutlineRepository) -> Completable {
        switch key.filter {
        case .category:
            return sortByCategory(outlineRepo: key).map { [weak self] value in
                self?.data[key] = value
            }.asCompletable()
        case .language:
            return sortByLanguage(outlineRepo: key).map { [weak self] value in
                self?.data[key] = value
            }.asCompletable()
        }
    }
    
    private func updateData(with repositories: [LoadedRepository]) -> Completable {
        self.data = MainOutlineMap()

        return Observable.from(repositories)
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .flatMap { (repo: LoadedRepository) -> Completable in
                let filter = OutlineFilter.language
                let outlineRepository = OutlineRepository(filter: filter, repo: repo)
                return self.updateFilters(key: outlineRepository)
            }.asCompletable()
//            .subscribe(onError: { print("Error: \($0)") }).disposed(by: bag)
    }
    
    private func bindUpdatePackageList() -> Disposable {
        let single: Single<([LoadedRepository], [URL : RepoRecord])> = Single.zip(
                AppContext.packageStore.repoIndexes(),
                AppContext.packageStore.getRepoRecords()
            )
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)

        let completable = single.flatMapCompletable { [weak self] (repos, records) in
            guard let `self` = self else { return Completable.empty() }
            let filtered = repos.filter { records[$0.index.url] != nil }
            return self.updateData(with: filtered)
        }

        return completable
            .subscribe(onCompleted: { [weak self] in
                guard let `self` = self else { return }
//                self.updateData(with: repos)
                self.view.updateProgressIndicator(isEnabled: false)
                self.view.setRepositories(data: self.data)

            }, onError: { [weak self] in self?.view.handle(error: $0) })
    }

    private func refreshRepos() -> Disposable {
        return Single.zip(AppContext.packageStore.repoIndexes(), AppContext.packageStore.getRepoRecords())
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (repos, records) in
                guard let `self` = self else { return }
                self.view.repositoriesChanged(repos: repos, records: records)
            }) { error in
                print("Error: \(error)")
        }
    }

    private func bindReposChanged() -> Disposable {
        return AppContext.packageStore.notifications()
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (notification) in
                if case PahkatNotification.repositoriesChanged = notification {
                    self.bindUpdatePackageList().disposed(by: self.bag)
                    self.refreshRepos().disposed(by: self.bag)
                }
            })
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
                PackageAction(key: package.key, action: package.action, target: package.target)
            }

            AppContext.startTransaction(actions: actions)
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
                        .observeOn(MainScheduler.instance)
                        .subscribeOn(MainScheduler.instance)
                        .subscribe(onCompleted: { [weak self] in
                            guard let `self` = self else { return }
                            for action in self.selectedPackages.values {
                                self.setPackageState(to: .set(action), package: action.package, repo: repo)
                            }
                            self.view.setRepositories(data: self.data)
                        }).disposed(by: self.bag)
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
            bindReposChanged(),
            refreshRepos()
        ])
    }
}

