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
//import BTree

class MainViewController: DisposableViewController<MainView>, MainViewable, NSToolbarDelegate {
    private lazy var presenter = { MainPresenter(view: self) }()
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
        self.contentView.outlineView.expandItem(nil, expandChildren: true)
        
        // This forces resizing to work correctly.
        self.refreshRepositories()
    }
    
    func refreshRepositories() {
        contentView.outlineView.beginUpdates()
        contentView.outlineView.reloadData(
            forRowIndexes: IndexSet(integersIn: 0..<self.dataSource.rowCount()),
            columnIndexes: IndexSet(integersIn: 0..<contentView.outlineView.tableColumns.count))
        contentView.outlineView.endUpdates()
        contentView.outlineView.sizeLastColumnToFit()
    }
    
    func update(title: String) {
        self.title = title
        contentView.primaryLabel.stringValue = title
    }
    
    func updateProgressIndicator(isEnabled: Bool) {
        DispatchQueue.main.async {
            if isEnabled {
                self.contentView.progressIndicator.startAnimation(self)
            } else {
                self.contentView.progressIndicator.stopAnimation(self)
            }
        }
    }
    
    private func sortPackages(packages: [PackageKey: SelectedPackage]) -> [SelectedPackage] {
        return packages.values
            .sorted(by: { (a, b) in
                if (a.isInstalling && b.isInstalling) || (a.isUninstalling && b.isUninstalling) {
                    // TODO: fix when dependency management is added
//                    return a.key < b.key
                    todo()
                }
                
                return a.isUninstalling
            })
    }
    
    func showDownloadView(with packages: [PackageKey: SelectedPackage]) {
//        let txActions = self.sortPackages(packages: packages).map { (x) -> TransactionAction<InstallerTarget> in
//            switch x.action {
//            case .install:
//                return TransactionAction<InstallerTarget>.install(x.key, target: x.target)
//            case .uninstall:
//                return TransactionAction<InstallerTarget>.uninstall(x.key, target: x.target)
//            }
//        }
//
//        let reposSingle: Single<[LoadedRepository]> = AppContext.store.state
//            .map { $0.repositories }
//            .take(1)
//            .asSingle()
//
//        Single
//            .zip(
//                PackageStoreProxy.instance.transaction(actions: txActions),
//                reposSingle
//            )
//            .subscribe(onSuccess: { (tx, repos) in
//                DispatchQueue.main.async {
//                    AppContext.windows.set(
//                        DownloadViewController(transaction: tx, repos: repos),
//                        for: MainWindowController.self)
//                }
//            }, onError: { error in
//                DispatchQueue.main.async {
//                    self.handle(error: error)
//                }
//            }).disposed(by: bag)
        todo()
    }
    
    func showSettings() {
        AppContext.windows.show(SettingsWindowController.self)
    }
    
    override func keyDown(with event: NSEvent) {
        if let character = event.characters?.first, character == " " && contentView.outlineView.selectedRow > -1 {
            guard let item = contentView.outlineView.item(atRow: contentView.outlineView.selectedRow) else {
                return
            }
            
            switch item {
            case let item as OutlineGroup:
                onPackageEventSubject.onNext(OutlineEvent.toggleGroup(item))
            case let item as OutlinePackage:
                onPackageEventSubject.onNext(OutlineEvent.togglePackage(item))
            default:
                break
            }
        } else {
            super.keyDown(with: event)
        }
    }
    
    func updateSettingsButton(isEnabled: Bool) {
        DispatchQueue.main.async {
            self.contentView.settingsButton.isEnabled = isEnabled
        }
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
        print(Thread.callStackSymbols.joined(separator: "\n"))
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = String(describing: error)
            
            alert.alertStyle = .critical
            log.error(error)
            alert.runModal()
            
            self.contentView.settingsButton.isEnabled = true
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "settings":
            let item = NSToolbarItem(view: contentView.settingsButton, identifier: itemIdentifier)
            item.maxSize = NSSize(width: CGFloat(48.0), height: item.maxSize.height)
            return item
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
        
        dataSource.events.subscribe(onPackageEventSubject).disposed(by: bag)
        
        contentView.outlineView.delegate = self.dataSource
        contentView.outlineView.dataSource = self.dataSource
        
        contentView.outlineView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        contentView.settingsButton.isEnabled = false
        self.update(title: Strings.appName)
        updatePrimaryButton(isEnabled: false, label: Strings.noPackagesSelected)
        
        presenter.start().disposed(by: bag)
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        contentView.outlineView.sizeLastColumnToFit()
    }
}

enum OutlineContextMenuItem {
    case SelectedPackage(SelectedPackage)
    case filter(OutlineRepository, OutlineFilter)
}

class MainViewControllerDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSOutlineViewMenu {
    fileprivate let events = PublishSubject<OutlineEvent>()
    fileprivate var repos: MainOutlineMap = MainOutlineMap()
    
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
            case let .SelectedPackage(action):
                events.onNext(OutlineEvent.setPackageSelection(action))
            case let .filter(repo, filter):
                events.onNext(OutlineEvent.changeFilter(repo, filter))
            }
        }
    }
    
    private func makeMenuItem(_ title: String, value: Any) -> NSMenuItem {
        return NSMenuItem(title: title, value: value, target: self, action: #selector(MainViewControllerDataSource.onMenuItemSelected(_:)))
    }
    
    func outlineView(_ outlineView: NSOutlineView, menuFor item: Any) -> NSMenu? {
        let menu = NSMenu()
        
        let selectedRepo: OutlineRepository
        
        switch item {
        case is OutlineRepository:
            return nil
        case let item as OutlinePackage:
            guard let installer = item.target.macOSPackage() else { return nil }
            
            let (status, target) = item.status
            
            let key = item.repo.repo.packageKey(for: item.package)
            let package = item.package
            
            switch status {
            case .notInstalled:
                if installer.targets.contains(.system) {
                    let v = SelectedPackage(key: key, package: package, action: .install, target: .system)
                    menu.addItem(makeMenuItem(Strings.installSystem, value: OutlineContextMenuItem.SelectedPackage(v)))
                }
                if installer.targets.contains(.user) {
                    let v = SelectedPackage(key: key, package: package, action: .install, target: .user)
                    menu.addItem(makeMenuItem(Strings.installUser, value: OutlineContextMenuItem.SelectedPackage(v)))
                }
            case .requiresUpdate:
                let v = SelectedPackage(key: key, package: package, action: .install, target: target)
                menu.addItem(makeMenuItem(Strings.update, value: OutlineContextMenuItem.SelectedPackage(v)))
            default:
                break
            }
            
            switch status {
            case .upToDate, .requiresUpdate:
                let v = SelectedPackage(key: key, package: package, action: .uninstall, target: target)
                menu.addItem(makeMenuItem(Strings.uninstall, value: OutlineContextMenuItem.SelectedPackage(v)))
            default:
                break
            }
            
            menu.addItem(NSMenuItem.separator())
            
            selectedRepo = item.repo
        case let item as OutlineGroup:
            selectedRepo = item.repo
        default:
            return nil
        }
        
        let sortMenu = NSMenu()
        let sortItem = NSMenuItem(title: Strings.sortBy)
        sortItem.submenu = sortMenu
        
        let categoryItem = makeMenuItem(Strings.category, value: OutlineContextMenuItem.filter(selectedRepo, .category))
        categoryItem.state = selectedRepo.filter == .category ? .on : .off
        sortMenu.addItem(categoryItem)
        
        let languageItem = makeMenuItem(Strings.language, value: OutlineContextMenuItem.filter(selectedRepo, .language))
        languageItem.state = selectedRepo.filter == .language ? .on : .off
        sortMenu.addItem(languageItem)
        menu.addItem(sortItem)
        
        return menu
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case is OutlineGroup, is OutlineRepository:
            return true
        default:
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        switch item {
        case nil:
            // If only one repo, we want to hide the repo from the outline.
            return repos.count == 1 ? repos[repos.keys.first!]!.count : repos.count
        case let item as OutlineRepository:
            return repos[item]!.count
        case let item as OutlineGroup:
            return repos[item.repo]![item]!.count
//            return repos[item.repo]![item]?.count ?? 0
        default:
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        switch item {
        case nil:
            // If only one repo, we want to hide the repo from the outline.
            if repos.count > 1 {
                let keyIndex = repos.keys.index(repos.keys.startIndex, offsetBy: index)
                return repos.keys[keyIndex]
            } else {
                let repo = repos.first!
                let group = repo.1[repo.1.index(repo.1.startIndex, offsetBy: index)]
                return group.0
            }
        case let item as OutlineRepository:
            log.debug(item.repo.index.url.absoluteString)
            let x = repos[item]!
            let keyIndex = x.index(x.startIndex, offsetBy: index)
            let outlineGroup = x[keyIndex]
            return outlineGroup.0
        case let item as OutlineGroup:
            let x = repos[item.repo]![item]!
            return x[index]
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
        guard let tableColumn = tableColumn else { return nil }
        guard let column = MainViewOutlineColumns(identifier: tableColumn.identifier) else { return nil }
        let cell = outlineView.makeView(withIdentifier: tableColumn.identifier, owner: outlineView) as! NSTableCellView
        
        switch item {
        case let outlineRepo as OutlineRepository:
            guard case .name = column else {
                cell.textField?.stringValue = ""
                return cell
            }
            if let button = cell.nextKeyView as? OutlineCheckbox {
                button.isHidden = true
            }

            let bold: [NSAttributedString.Key: Any]
            if #available(OSX 10.11, *) {
                bold = [kCTFontAttributeName as NSAttributedString.Key: NSFont.systemFont(ofSize: 13, weight: .semibold)]
            } else {
                bold = [kCTFontAttributeName as NSAttributedString.Key: NSFont.boldSystemFont(ofSize: 13)]
            }

            cell.textField?.attributedStringValue = NSAttributedString(string: outlineRepo.repo.index.nativeName, attributes: bold)

            cell.textField?.toolTip = nil
            break
        case let item as OutlineGroup:
            let group = item
            let outlineRepo = item.repo
            let id = group.id
            let name = group.value

            guard case .name = column else {
                cell.textField?.stringValue = ""
                return cell
            }

            cell.textField?.stringValue = name

            let packages = repos[outlineRepo]![group]!
//            guard let packages = repos[outlineRepo]![group] else {
//                return nil
//            }

            if let button = cell.nextKeyView as? OutlineCheckbox {
                button.target = self
                button.action = #selector(MainViewControllerDataSource.onCheckboxChanged(_:))
                button.event = OutlineEvent.toggleGroup(item)
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
                    let i = packages.reduce(0, { (acc, cur) in return acc + (cur.selection == nil ? 0 : 1) })
                    
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
            
            let bold: [NSAttributedString.Key: Any]
            if #available(OSX 10.11, *) {
                bold = [kCTFontAttributeName as NSAttributedString.Key: NSFont.systemFont(ofSize: 13, weight: .semibold)]
            } else {
                bold = [kCTFontAttributeName as NSAttributedString.Key: NSFont.boldSystemFont(ofSize: 13)]
            }
            
            cell.textField?.attributedStringValue = NSAttributedString(string: name, attributes: bold)
            break
        case let item as OutlinePackage:
            switch column {
            case .name:
                let package = item.package
                guard let button = cell.nextKeyView as? OutlineCheckbox else {
                    return nil
                }

                button.target = self
                button.action = #selector(MainViewControllerDataSource.onCheckboxChanged(_:))
                button.event = OutlineEvent.togglePackage(item)
                button.allowsMixedState = false
                button.isHidden = false
                
                button.toolTip = package.nativeName
                cell.textField?.toolTip = package.nativeName
                
                if item.selection != nil {
                    button.state = .on
                } else {
                    button.state = .off
                }
                cell.textField?.stringValue = package.nativeName
                let baseWidth = cell.textField?.attributedStringValue.size().width ?? CGFloat(0.0)
                let repoAdjustedWidth = CGFloat(repos.count == 1 ? 64.0 : 96.0)
                tableColumn.width = max(tableColumn.width, baseWidth + repoAdjustedWidth)
            case .version:
                let size = Int64(item.target.macOSPackage()?.size ?? 0)
                cell.textField?.stringValue = "\(item.release.version ?? "<unknown>") (\(byteCountFormatter.string(fromByteCount: size)))"
                let a = cell.textField?.attributedStringValue.size().width ?? CGFloat(0.0)
                tableColumn.width = max(tableColumn.width, a)
            case .state:
                if let selectedPackage = item.selection {
                    let paraStyle = NSMutableParagraphStyle()
                    paraStyle.alignment = .left
                    
                    var attrs = [NSAttributedString.Key: Any]()
                    if #available(OSX 10.11, *) {
                        attrs[kCTFontAttributeName as NSAttributedString.Key] = NSFont.systemFont(ofSize: 13, weight: .semibold)
                    } else {
                        attrs[kCTFontAttributeName as NSAttributedString.Key] = NSFont.boldSystemFont(ofSize: 13)
                    }
                    
                    attrs[NSAttributedString.Key.paragraphStyle] = paraStyle
                    
                    let msg: String
                    switch selectedPackage.target {
                    case .system:
                        msg = selectedPackage.description
                    case .user:
                        msg = Strings.userDescription(description: selectedPackage.description)
                    }
                    
                    cell.textField?.attributedStringValue = NSAttributedString(string: msg, attributes: attrs)
                    
                    let a = cell.textField?.attributedStringValue.size().width ?? CGFloat(0.0)
                    tableColumn.width = max(tableColumn.width, a)
                } else {
                    let (status, target) = item.status
                    if status == .notInstalled {
                        cell.textField?.stringValue = status.description
                    } else {
                        switch target {
                        case .system:
                            cell.textField?.stringValue = status.description
                        case .user:
                            cell.textField?.stringValue = Strings.userDescription(description: status.description)
                        }
                    }
                }
            }
        default:
            return cell
        }
        
        let withCheckboxX: CGFloat = 24
        let withoutCheckboxX: CGFloat = 8
        let textFieldWidth: CGFloat = 205
        
        // Offset textfield if checkbox is visible
        if cell.nextKeyView?.isHidden ?? false {
            cell.textField?.frame = CGRect(x: withoutCheckboxX, y: 0, width: textFieldWidth, height: cell.frame.height)
        } else {
            cell.textField?.frame = CGRect(x: withCheckboxX, y: 0, width: textFieldWidth, height: cell.frame.height)
        }
        
        return cell
    }
    
    deinit {
        events.onCompleted()
    }
}

