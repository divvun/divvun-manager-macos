import Cocoa
import WebKit
import RxSwift
import RxCocoa

class LandingViewController: DisposableViewController<LandingView>, NSToolbarDelegate, WebBridgeViewable {
    private var repos: [LoadedRepository] = []

    private lazy var bridge = { WebBridgeService(webView: self.contentView.webView, view: self) }()
    
    private lazy var onSettingsTapped: Driver<Void> = {
        // Main settings button
        return self.contentView.settingsButton.rx.tap.asDriver()
    }()

    private lazy var onOpenSettingsTapped: Driver<Void> = {
        // The settings button that appears when no repos are configured
        return self.contentView.openSettingsButton.rx.tap.asDriver()
    }()

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "settings":
            let item = NSToolbarItem(view: contentView.settingsButton, identifier: itemIdentifier)
            item.maxSize = NSSize(width: CGFloat(48.0), height: item.maxSize.height)
            return item
        case "repo-selector":
            return NSToolbarItem.init(view: contentView.popupButton, identifier: itemIdentifier)
        default:
            return nil
        }
    }

    var onRepoDropdownChanged: Observable<LoadedRepository?> {
        return AppContext.settings.selectedRepository
            .flatMapLatest { url -> Observable<LoadedRepository?> in
                return AppContext.packageStore.repoIndexes().map { repos in
                    if let url = url, let repo = repos.first(where: { $0.index.url == url }) {
                        return repo
                    } else if let repo = repos.first {
                        return repo
                    }

                    return nil
                }.asObservable()
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureToolbar()
    }

    private func makeRepoPopup() {
        Single.zip(AppContext.packageStore.repoIndexes(), AppContext.packageStore.getRepoRecords())
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (repos, records) in
                guard let `self` = self else { return }

                self.repos = repos.filter { records[$0.index.url] != nil }

                let popupButton = self.contentView.popupButton
                let selectedRepoUrl: URL? = AppContext.settings.read(key: .selectedRepository)

                popupButton.removeAllItems()
                self.repos.forEach { (repo) in
                    let name = repo.index.nativeName
                    let url = repo.index.url
                    let menuItem = NSMenuItem(title: name)
                    menuItem.representedObject = url
                    popupButton.menu?.addItem(menuItem)

                    if let selectedUrl = selectedRepoUrl, url == selectedUrl {
                           popupButton.select(menuItem)
                    }
                }

                popupButton.menu?.addItem(NSMenuItem.separator())

                let showDetailedItem = NSMenuItem(title: Strings.showDetailedView)
                showDetailedItem.representedObject = URL(string: "divvun-installer:detailed")
                popupButton.menu?.addItem(showDetailedItem)

                popupButton.action = #selector(self.popupItemSelected)
                popupButton.target = self
            }) { error in
                print("Error: \(error)")
        }.disposed(by: self.bag)
    }

    private func showNoSelection() {
        print("No selection")
        // Brendan said this would work
        let url: URL? = nil
        try? AppContext.settings.write(key: .selectedRepository, value: url)
        self.showEmptyStateIfNeeded()
    }

    private func showNoLandingPage() {
        print("No landing page")
        self.showMain()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        bindRepoDropdown()
        bindSettingsButton()
        bindOpenSettingsButton()
        bindPrimaryButton()
        bindRepositoriesChanged()
        makeRepoPopup()
    }

    private func bindRepoDropdown() {
        self.onRepoDropdownChanged
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] repo in
                if let repo = repo {
                    if let url = repo.index.landingURL {
                        self?.bridge.start(url: url, repo: repo)
                    } else {
                        // Show a view saying that this repo has no landing page, and to go to detailed view.
                        self?.showNoLandingPage()
                    }
                } else {
                    self?.showNoSelection()
                    // Show a view saying no selection.
                }
            }).disposed(by: bag)
    }
    
    private func bindSettingsButton() {
        self.onSettingsTapped.drive(onNext: { [weak self] in
            self?.showSettings()
        }).disposed(by: bag)
    }

    private func bindOpenSettingsButton() {
        self.onOpenSettingsTapped.drive(onNext: { [weak self] in
            self?.showSettings()
        }).disposed(by: bag)
    }

    private func bindPrimaryButton() {
        contentView.primaryButton.rx.tap.subscribe(onNext: { _ in
            self.showMain()
        }).disposed(by: bag)
    }

    private func bindRepositoriesChanged() {
        AppContext.packageStore.notifications()
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notification) in
                if case PahkatNotification.repositoriesChanged = notification {
                    self?.showEmptyStateIfNeeded()
                    self?.makeRepoPopup()
                }
            }).disposed(by: bag)
    }

    func showSettings() {
        AppContext.windows.show(SettingsWindowController.self)
    }

    func showEmptyStateIfNeeded() {
        AppContext.packageStore.getRepoRecords()
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (records: [URL: RepoRecord]) in
                let empty = records.count <= 0
                let state = empty
                    ? LandingView.State.empty
                    : LandingView.State.normal
                self.contentView.updateView(state: state)
            }) { error in
                print("Error: \(error)")
        }.disposed(by: self.bag)
    }

    private func showMain() {
        AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
    }

    private func configureToolbar() {
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        
        window.titleVisibility = .hidden
        window.toolbar!.isVisible = true
        window.toolbar!.delegate = self

        let toolbarItems = ["settings",
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "repo-selector",
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue]

        window.toolbar!.setItems(toolbarItems)
    }

    @objc func popupItemSelected() {
        guard let url = contentView.popupButton.selectedItem?.representedObject as? URL else {
            // TODO: error or something
            return
        }
        do {
            try AppContext.settings.write(key: .selectedRepository, value: url)
        } catch {
            print("Error setting selected repo: \(error)")
        }
    }
    
    func handle(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = String(describing: error)
            
            alert.alertStyle = .critical
            log.error(error)
            alert.runModal()
            
            self.contentView.webView.reload()
        }
    }
}
