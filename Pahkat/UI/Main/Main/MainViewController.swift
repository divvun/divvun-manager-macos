//
//  MainViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa
import BTree

class MainViewController: DisposableViewController<MainView>, MainViewable, NSToolbarDelegate {
    private lazy var presenter = { MainPresenter(view: self) }()
//    private var repo: RepositoryIndex? = nil
//    private var statuses = [String: PackageInstallStatus]()
    private var dataSource = MainViewControllerDataSource()
    
    let onPackageEventSubject = PublishSubject<OutlineEvent>()
    var onPackageEvent: Observable<OutlineEvent> {
        return onPackageEventSubject.asObservable()
    }
    
    lazy var onSettingsTapped: Driver<Void> = {
        return self.contentView.settingsButton.rx.tap.asDriver()
    }()
    
    lazy var onPrimaryButtonPressed: Driver<Void> = {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }()
    
    deinit {
        onPackageEventSubject.onCompleted()
        print("MAIN DEINIT")
    }
    
    func setRepositories(data: MainOutlineMap) {
        dataSource.repos = data
        contentView.outlineView.reloadData()
//        refreshRepositories()
    }
    
    func refreshRepositories() {
        contentView.outlineView.beginUpdates()
        contentView.outlineView.reloadData(
            forRowIndexes: IndexSet(integersIn: 0..<self.dataSource.rowCount()),
            columnIndexes: IndexSet(integersIn: 0..<contentView.outlineView.tableColumns.count))
        contentView.outlineView.endUpdates()
    }
    
    func update(title: String) {
        self.title = title
    }
    
    func showDownloadView(with packages: [URL: PackageAction]) {
        AppContext.windows.set(DownloadViewController(packages: packages), for: MainWindowController.self)
    }
    
    func showSettings() {
        AppContext.windows.show(SettingsWindowController.self)
    }
    
    override func keyUp(with event: NSEvent) {
        if let character = event.characters?.first, character == " " && contentView.outlineView.selectedRow > -1 {
            guard let item = contentView.outlineView.item(atRow: contentView.outlineView.selectedRow) as? OutlineItem else {
                fatalError("Item must always be of type OutlineItem")
            }
            
            switch item {
            case .repository:
                break
            case let .group(group, repo):
                onPackageEventSubject.onNext(OutlineEvent.toggleGroup(repo, group))
            case let .item(package, _, repo):
                onPackageEventSubject.onNext(OutlineEvent.togglePackage(repo, package.package))
            }
        }
        
        super.keyUp(with: event)
    }
    
    func updatePrimaryButton(isEnabled: Bool, label: String) {
        contentView.primaryButton.isEnabled = isEnabled
        contentView.primaryButton.title = label
        
        contentView.primaryButton.sizeToFit()
        contentView.primaryLabel.sizeToFit()
        
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        window.toolbar!.redraw()
    }
    
    func handle(error: Error) {
        print(error)
        // TODO: show errors in a meaningful way to the user
        fatalError("Not implemented")
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "settings":
            return NSToolbarItem(view: contentView.settingsButton, identifier: itemIdentifier)
        case "button":
            contentView.primaryButton.sizeToFit()
            return NSToolbarItem(view: contentView.primaryButton, identifier: itemIdentifier)
        case "title":
            contentView.primaryLabel.sizeToFit()
            return NSToolbarItem(view: contentView.primaryLabel, identifier: itemIdentifier)
        default:
            return nil
        }
    }
    
    private func row<T>(for targetItem: T) -> Int where T: Equatable {
        var i = 0
        
        while let anyItem = contentView.outlineView.item(atRow: i) {
            i += 1
            
            guard let item = anyItem as? T else {
                continue
            }
            
            if targetItem == item {
                return i
            }
        }
        
        return -1
    }
    
    private func rowCount() -> Int {
        var i = 0
        
        while let _ = contentView.outlineView.item(atRow: i) {
            i += 1
        }
        
        return i
    }
    
    private func configureToolbar() {
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        
        window.titleVisibility = .hidden
        window.toolbar!.isVisible = true
        window.toolbar!.delegate = self
        
        let toolbarItems = ["settings",
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "title",
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "button"]
        
        window.toolbar!.setItems(toolbarItems)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureToolbar()
        contentView.settingsButton.isEnabled = false
        // TODO move to presenter?
        // Always update the repos on load.
        AppContext.settings.state.take(1).map { $0.repositories }
            .flatMapLatest { (configs: [RepoConfig]) -> Observable<[RepositoryIndex]> in
                return try AppDelegate.instance.requestRepos(configs)
            }
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] repos in
                print("Refreshed repos in main view.")
                self?.contentView.settingsButton.isEnabled = true
                AppContext.store.dispatch(event: AppEvent.setRepositories(repos))
            })
            .disposed(by: bag)
        
        dataSource.events.subscribe(onPackageEventSubject).disposed(by: bag)
        
        contentView.outlineView.delegate = self.dataSource
        contentView.outlineView.dataSource = self.dataSource
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        contentView.primaryLabel.stringValue = Strings.appName
        updatePrimaryButton(isEnabled: false, label: Strings.noPackagesSelected)
        
        presenter.start().disposed(by: bag)
    }
}

enum OutlineContextMenuItem {
    case packageAction(PackageAction)
    case filter(OutlineRepository, Repository.PrimaryFilter)
}

class MainViewControllerDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSOutlineViewMenu {
    fileprivate let events = PublishSubject<OutlineEvent>()
    fileprivate var repos: MainOutlineMap = Map()
    
    private let byteCountFormatter = ByteCountFormatter()
    
    override init() {
        super.init()
    }
    
    func rowCount() -> Int {
        var i = 0
        
        // Get number of categories for each repo
        repos.forEach {
            i += 1
            i += $0.1.keys.count
            $0.1.values.forEach { i += $0.count }
        }
        
        return i
    }
    
    @objc func onMenuItemSelected(_ item: Any) {
        guard let item = item as? NSMenuItem else { return }
        
        if let value = item.representedObject as? OutlineContextMenuItem {
            switch value {
            case let .packageAction(action):
                events.onNext(OutlineEvent.setPackageAction(action))
            case let .filter(repo, filter):
                events.onNext(OutlineEvent.changeFilter(repo, filter))
            }
        }
    }
    
    private func makeMenuItem(_ title: String, value: Any) -> NSMenuItem {
        return NSMenuItem(title: title, value: value, target: self, action: #selector(MainViewControllerDataSource.onMenuItemSelected(_:)))
    }
    
    func outlineView(_ outlineView: NSOutlineView, menuFor item: Any) -> NSMenu? {
        guard let item = item as? OutlineItem else { return nil }
        let menu = NSMenu()
        
        let selectedRepo: OutlineRepository
        
        switch item {
        case .repository:
            return nil
        case let .item(item, _, repo):
            guard let outlineStatus = repo.repo.status(for: item.package) else { return nil }
            guard case let .macOsInstaller(installer) = item.package.installer else { fatalError() }
            
            let status = outlineStatus.status
            let target = outlineStatus.target
            
            switch status {
            case .notInstalled:
                if installer.targets.contains(.system) {
                    menu.addItem(makeMenuItem("Install (System)", value: OutlineContextMenuItem.packageAction(.install(repo.repo, item.package, .system))))
                }
                if installer.targets.contains(.user) {
                    menu.addItem(makeMenuItem("Install (User)", value: OutlineContextMenuItem.packageAction(.install(repo.repo, item.package, .user))))
                }
            case .requiresUpdate, .versionSkipped:
                menu.addItem(makeMenuItem("Update", value: OutlineContextMenuItem.packageAction(.install(repo.repo, item.package, target))))
            default:
                break
            }
            
            switch status {
            case .upToDate, .requiresUpdate, .versionSkipped:
                menu.addItem(makeMenuItem("Uninstall", value: OutlineContextMenuItem.packageAction(.uninstall(repo.repo, item.package, target))))
            default:
                break
            }
            
            menu.addItem(NSMenuItem.separator())
            
            selectedRepo = repo
        case let .group(_, repo):
            selectedRepo = repo
        }
        
        let sortMenu = NSMenu()
        let sortItem = NSMenuItem(title: "Sort by…")
        sortItem.submenu = sortMenu
        
        let categoryItem = makeMenuItem("Category", value: OutlineContextMenuItem.filter(selectedRepo, .category))
        categoryItem.state = selectedRepo.filter == .category ? .on : .off
        sortMenu.addItem(categoryItem)
        
        let languageItem = makeMenuItem("Language", value: OutlineContextMenuItem.filter(selectedRepo, .language))
        languageItem.state = selectedRepo.filter == .language ? .on : .off
        sortMenu.addItem(languageItem)
        menu.addItem(sortItem)
        
        return menu
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? OutlineItem else { return false }
        switch item {
        case .group(_), .repository(_):
            return true
        default:
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? OutlineItem else {
            // If only one repo, we want to hide the repo from the outline.
            return repos.count == 1 ? repos[repos.keys.first!]!.count : repos.count
        }
        
        switch item {
        case let .repository(repo):
            return repos[repo]!.count
        case let .group(group, repo):
            return repos[repo]![group]!.count
        case .item:
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if !(item is OutlineItem) && repos.count > 1 {
            // Return repo pile if > 1 repo, else start with repo's groups
            let keyIndex = repos.keys.index(repos.keys.startIndex, offsetBy: index)
            return OutlineItem.repository(repos.keys[keyIndex])
        }
        
        let item = (item as? OutlineItem) ?? OutlineItem.repository(repos.keys.first!)
        
        switch item {
        case let .repository(repo):
            let x = repos[repo]!
            let keyIndex = x.keys.index(x.keys.startIndex, offsetBy: index)
            let outlineGroup = x.keys[keyIndex]
            return OutlineItem.group(outlineGroup, repo)
        case let .group(group, repo):
            let x = repos[repo]![group]!
            
            return OutlineItem.item(x[index], group, repo)
        default: // number of repositories
            fatalError()
        }
    }
    
    @objc func onCheckboxChanged(_ sender: Any) {
        guard let button = sender as? OutlineCheckbox else { return }
        
        if let event = button.event {
            self.events.onNext(event)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? OutlineItem else { return nil }
        guard let tableColumn = tableColumn else { return nil }
        guard let column = MainViewOutlineColumns(identifier: tableColumn.identifier) else { return nil }
        let cell = outlineView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        
        switch item {
        case let .repository(outlineRepo):
            guard case .name = column else {
                cell.textField?.stringValue = ""
                return cell
            }
            if let button = cell.nextKeyView as? OutlineCheckbox {
                button.isHidden = true
            }
            cell.textField?.stringValue = outlineRepo.repo.meta.nativeName
            cell.textField?.toolTip = nil
        case let .group(group, outlineRepo):
            let name = group.value
            let id = group.id
            
            guard case .name = column else {
                cell.textField?.stringValue = ""
                return cell
            }
            
            cell.textField?.stringValue = name
            
            let packages = repos[outlineRepo]![group]!
            
            if let button = cell.nextKeyView as? OutlineCheckbox {
                button.target = self
                button.action = #selector(MainViewControllerDataSource.onCheckboxChanged(_:))
                button.event = OutlineEvent.toggleGroup(outlineRepo, group)
                if outlineRepo.filter == .category {
                    button.toolTip = name
                    cell.textField?.toolTip = name
                } else {
                    let tooltip = ISO639.get(tag: id)?.name ?? name
                    button.toolTip = tooltip
                    cell.textField?.toolTip = tooltip
                }
                
                button.isHidden = false
                
                let groupState: NSControl.StateValue = {
                    let i = packages.reduce(0, { (acc, cur) in return acc + (cur.action == nil ? 0 : 1) })
                    
                    if i == 0 {
                        return .off
                    } else if packages.count == i {
                        return .on
                    } else {
                        return .mixed
                    }
                }()
                
                // Enable mixed state only if group state needs to be mixed, disable otherwise.
                button.allowsMixedState = groupState == .mixed
                
                button.state = groupState
                cell.textField?.stringValue = name
            }
            
            let bold: [NSAttributedStringKey: Any]
            if #available(OSX 10.11, *) {
                bold = [kCTFontAttributeName as NSAttributedStringKey: NSFont.systemFont(ofSize: 13, weight: .semibold)]
            } else {
                bold = [kCTFontAttributeName as NSAttributedStringKey: NSFont.boldSystemFont(ofSize: 13)]
            }
            
            cell.textField?.attributedStringValue = NSAttributedString(string: group.value, attributes: bold)
//            cell.textField?.stringValue = group.value
        case let .item(item, _, repo):
            switch column {
            case .name:
                let package = item.package
                let button = cell.nextKeyView as! OutlineCheckbox
                
                button.target = self
                button.action = #selector(MainViewControllerDataSource.onCheckboxChanged(_:))
                button.event = OutlineEvent.togglePackage(repo, item.package)
                button.allowsMixedState = false
                button.isHidden = false
                
                button.toolTip = package.nativeName
                cell.textField?.toolTip = package.nativeName
                
                if item.action != nil {
                    button.state = .on
                } else {
                    button.state = .off
                }
                cell.textField?.stringValue = package.nativeName
            case .version:
                cell.textField?.stringValue = "\(item.package.version) (\(byteCountFormatter.string(fromByteCount: item.package.installer.size)))"
            case .state:
                if let selectedPackage = item.action {
                    let paraStyle = NSMutableParagraphStyle()
                    paraStyle.alignment = .left
                    
                    var attrs = [NSAttributedStringKey: Any]()
                    if #available(OSX 10.11, *) {
                        attrs[kCTFontAttributeName as NSAttributedStringKey] = NSFont.systemFont(ofSize: 13, weight: .semibold)
                    } else {
                        attrs[kCTFontAttributeName as NSAttributedStringKey] = NSFont.boldSystemFont(ofSize: 13)
                    }
                    
                    attrs[NSAttributedStringKey.paragraphStyle] = paraStyle
                    
                    let msg: String
                    switch selectedPackage.target {
                    case .system:
                        msg = selectedPackage.description
                    case .user:
                        msg = "\(selectedPackage.description) (User)"
                    }
                    
                    cell.textField?.attributedStringValue = NSAttributedString(string: msg, attributes: attrs)
                } else {
                    if let response = repo.repo.status(for: item.package) {
                        if response.status == .notInstalled {
                            cell.textField?.stringValue = response.status.description
                        } else {
                            switch response.target {
                            case .system:
                                cell.textField?.stringValue = response.status.description
                            case .user:
                                cell.textField?.stringValue = "\(response.status.description) (User)"
                            }
                        }
                    } else {
                        cell.textField?.stringValue = Strings.downloadError
                    }
                }
            }
        }
        
        return cell
    }
    
    deinit {
        events.onCompleted()
    }
}

