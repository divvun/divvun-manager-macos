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


class MainViewController: DisposableViewController<MainView>, MainViewable, NSToolbarDelegate {
    private lazy var presenter = { MainPresenter(view: self) }()
    private var repo: RepositoryIndex? = nil
    private var statuses = [String: PackageInstallStatus]()
    private var dataSource: MainViewControllerDataSource! = nil
    
    let onPackagesToggledSubject = PublishSubject<[Package]>()
    var onPackagesToggled: Observable<[Package]> {
        return onPackagesToggledSubject.asObservable()
    }
    var onGroupToggled: Observable<[Package]> = Observable.empty()
    
    lazy var onSettingsTapped: Driver<Void> = {
        return self.contentView.settingsButton.rx.tap.asDriver()
    }()
    
    lazy var onPrimaryButtonPressed: Driver<Void> = {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }()
    
    deinit {
        onPackagesToggledSubject.onCompleted()
        print("MAIN DEINIT")
    }
    
    func setRepository(repo: RepositoryIndex, statuses: [String: PackageInstallStatus]) {
        //print(repo)
        self.repo = repo
        self.statuses = statuses
        dataSource = MainViewControllerDataSource(with: repo, statuses: statuses, filter: repo.meta.primaryFilter, outlet: onPackagesToggledSubject)
        contentView.outlineView.delegate = self.dataSource
        contentView.outlineView.dataSource = self.dataSource
    }
    
    func update(title: String) {
        self.title = title
    }
    
    func showDownloadView(with packages: [String: PackageAction]) {
        AppContext.windows.set(DownloadViewController(packages: packages), for: MainWindowController.self)
    }
    
    func showSettings() {
        AppContext.windows.show(SettingsWindowController.self)
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
    
    func updateSelectedPackages(packages: [String: PackageAction]) {
        self.dataSource.selectedPackages = packages
        
        contentView.outlineView.beginUpdates()
        contentView.outlineView.reloadData(
            forRowIndexes: IndexSet(integersIn: 0..<self.dataSource.rowCount()),
            columnIndexes: IndexSet(integersIn: 0..<contentView.outlineView.tableColumns.count))
        contentView.outlineView.endUpdates()
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
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        contentView.primaryLabel.stringValue = Strings.appName
        updatePrimaryButton(isEnabled: false, label: Strings.noPackagesSelected)
        
        presenter.start().disposed(by: bag)
    }
}

extension NSToolbarItem {
    convenience init(view: NSView, identifier: NSToolbarItem.Identifier) {
        self.init(itemIdentifier: identifier)
        self.view = view
    }
}

extension NSToolbar {
    func redraw() {
        // AHHAHAhahahahasdhiuafelhiuafewlihufewhiluafewilhuaefwhio!!!!11111oneoneoneetttetttetetettt
        self.setItems(identifiers: self.items.map { $0.itemIdentifier })
    }
    
    func setItems(_ strings: [String]) {
        self.setItems(identifiers: strings.map { NSToolbarItem.Identifier(rawValue: $0) })
    }
    
    func setItems(identifiers: [NSToolbarItem.Identifier]) {
        for i in (0..<self.items.count).reversed() {
            self.removeItem(at: i)
        }
        
        for i in 0..<identifiers.count {
            self.insertItem(withItemIdentifier: identifiers[i], at: self.items.count)
        }
    }
}

enum MainViewOutlineColumns: String {
    case name = "name"
    case version = "version"
    case state = "state"
    
    init?(identifier: NSUserInterfaceItemIdentifier) {
        if let value = MainViewOutlineColumns(rawValue: identifier.rawValue) {
            self = value
        } else {
            return nil
        }
    }
}

fileprivate typealias PackageMap = [String: [Package]]

fileprivate func categoryFilter(repo: RepositoryIndex) -> PackageMap {
    var data = PackageMap()
    
    repo.packages.values.forEach({
        if !data.keys.contains($0.category) {
            data[$0.category] = []
        }
        
        data[$0.category]!.append($0)
    })
    
    return data
}

fileprivate func languageFilter(repo: RepositoryIndex) -> PackageMap {
    var data = PackageMap()
    
    repo.packages.values.forEach { package in
        package.languages.forEach { language in
            if !data.keys.contains(language) {
                data[language] = []
            }
            
            data[language]!.append(package)
        }
    }
    
    return data
}

protocol NSOutlineViewMenu: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, menuFor item: Any) -> NSMenu?
}

class PackageOutlineView: NSOutlineView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = self.convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        guard let item = self.item(atRow: row) else {
            return nil
        }
        
        return (self.delegate as? NSOutlineViewMenu)?.outlineView(self, menuFor: item)
    }
}

enum OutlineItem: Equatable {
    case repository(RepositoryIndex)
    case group(String, String)
    case item(Package)
    
    static func ==(lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        switch (lhs, rhs) {
        case let (.repository(a), .repository(b)):
            return a == b
        case let (.group(a, aa), .group(b, bb)):
            return a == b && aa == bb
        case let (.item(a), .item(b)):
            return a == b
        default:
            return false
        }
    }
}

class MainViewControllerDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSOutlineViewMenu {
    let bag = DisposeBag()
    
    private let outlet: PublishSubject<[Package]>
    
    private let repos: [RepositoryIndex]
    private var data: PackageMap
    private var orderedDataKeys: [(String, String)]
    private let statuses: [String: PackageInstallStatus]
    private var filter: Repository.PrimaryFilter
    var selectedPackages = [String: PackageAction]()
    
    private let byteCountFormatter = ByteCountFormatter()
    
    func rowCount() -> Int {
        var i = 0
        
        // Get number of repos
        i += repos.count
        
        // Get number of categories for each repo
        i += data.keys.count
        
        // Get each package under the categories
        data.values.forEach { i += $0.count }
        
        return i
    }
    
    @objc func onMenuItemSelected(_ item: Any) {
        guard let item = item as? NSMenuItem else { return }
        
        if let value = item.representedObject as? Repository.PrimaryFilter {
            filter = value
            return
        }
        
        if let value = item.representedObject as? String {
            switch value {
            case "install.system":
                print("Install to system")
            case "install.user":
                print("Install to user")
            case "uninstall":
                print("Uninstall")
            default:
                return
            }
        }
    }
    
    private func makeMenuItem(_ title: String, value: Any) -> NSMenuItem {
        return NSMenuItem(title: title, value: value, target: self, action: #selector(MainViewControllerDataSource.onMenuItemSelected(_:)))
    }
    
    func outlineView(_ outlineView: NSOutlineView, menuFor item: Any) -> NSMenu? {
        guard let item = item as? OutlineItem else { return nil }
        let menu = NSMenu()
        
        switch item {
        case .repository:
            return nil
        case let .item(package):
            guard let status = statuses[package.id] else { return nil }
            guard case let .macOsInstaller(installer) = package.installer else { fatalError() }
            
            switch status {
            case .notInstalled, .requiresUpdate, .versionSkipped:
                if installer.targets.contains(.system) {
                    menu.addItem(makeMenuItem("Install (System)", value: "install.system"))
                }
                if installer.targets.contains(.user) {
                    menu.addItem(makeMenuItem("Install (User)", value: "install.user"))
                }
            default:
                break
            }
            
            switch status {
            case .upToDate, .requiresUpdate, .versionSkipped:
                menu.addItem(makeMenuItem("Uninstall", value: "uninstall"))
            default:
                break
            }
            
            menu.addItem(NSMenuItem.separator())
        default:
            break
        }
        
        let sortMenu = NSMenu()
        let sortItem = NSMenuItem(title: "Sort by…")
        sortItem.submenu = sortMenu
        sortMenu.addItem(makeMenuItem("Category", value: Repository.PrimaryFilter.category))
        sortMenu.addItem(makeMenuItem("Language", value: Repository.PrimaryFilter.language))
        menu.addItem(sortItem)
        
        return menu
    }
    
    private func set(filter: Repository.PrimaryFilter, for repo: RepositoryIndex) {
        switch filter {
        case .category:
            self.data = categoryFilter(repo: repo)
            self.orderedDataKeys = self.data.keys.sorted().map { ($0, $0) }
        case .language:
            self.data = languageFilter(repo: repo)
            self.orderedDataKeys = self.data.keys.sorted().map { (ISO639.get(tag: $0)?.autonym ?? ISO639.get(tag: $0)?.name ?? $0, $0) }
        }
    }
    
    init(with repo: RepositoryIndex, statuses: [String: PackageInstallStatus], filter: Repository.PrimaryFilter, outlet: PublishSubject<[Package]>) {
        self.repos = [repo]
        self.statuses = statuses
        self.filter = filter
        self.outlet = outlet
        
        switch filter {
        case .category:
            self.data = categoryFilter(repo: repo)
            self.orderedDataKeys = self.data.keys.sorted().map { ($0, $0) }
        case .language:
            self.data = languageFilter(repo: repo)
            self.orderedDataKeys = self.data.keys.sorted().map { (ISO639.get(tag: $0)?.autonym ?? ISO639.get(tag: $0)?.name ?? $0, $0) }
        }
    
        super.init()
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? OutlineItem else {
            return repos.count
        }
        
        switch item {
        case .repository:
            return data.keys.count
        case let .group(_, id):
            return data[id]!.count
        case .item:
            return 0
        }
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
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item as? OutlineItem else {
            // Return repo pile
            return OutlineItem.repository(repos[index])
        }
        
        switch item {
        case .repository:
            let (name, id) = orderedDataKeys[index]
            return OutlineItem.group(name, id)
        case let .group(_, id):
            return OutlineItem.item(data[id]![index])
        default: // number of repositories
            fatalError()
        }
    }
    
    @objc func onCheckboxChanged(_ sender: Any) {
        guard let button = sender as? OutlineCheckbox else { return }
        
        if let package = button.package {
            self.outlet.onNext([package])
        } else if let group = button.group, let packages = data[group] {
            let toggleIds = Set(selectedPackages.keys).intersection(packages.map { $0.id })
            let x = toggleIds.count > 0 ? toggleIds.map { id in packages.first(where: { id == $0.id })! } : packages
            self.outlet.onNext(x)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? OutlineItem else { return nil }
        guard let tableColumn = tableColumn else { return nil }
        guard let column = MainViewOutlineColumns(identifier: tableColumn.identifier) else { return nil }
        let cell = outlineView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        
        switch item {
        case let .repository(repo):
            guard case .name = column else {
                cell.textField?.stringValue = ""
                return cell
            }
            if let button = cell.nextKeyView as? OutlineCheckbox {
                button.isHidden = true
            }
            cell.textField?.stringValue = repo.meta.nativeName
            cell.textField?.toolTip = nil
        case let .group(name, id):
            guard case .name = column else {
                cell.textField?.stringValue = ""
                return cell
            }
            
            cell.textField?.stringValue = name
            
            let packages = data[id]!
            
            if let button = cell.nextKeyView as? OutlineCheckbox {
                button.target = self
                button.action = #selector(MainViewControllerDataSource.onCheckboxChanged(_:))
                button.group = id
                if filter == .category {
                    button.toolTip = name
                    cell.textField?.toolTip = name
                } else {
                    let tooltip = ISO639.get(tag: id)?.name ?? name
                    button.toolTip = tooltip
                    cell.textField?.toolTip = tooltip
                }
                
                button.isHidden = false
                
                let groupState: NSControl.StateValue = {
                    var i = 0
                    for package in packages {
                        if selectedPackages.keys.contains(package.id) {
                            i += 1
                            continue
                        }
                    }
                    
                    if i == 0 {
                        button.allowsMixedState = false
                        return .off
                    } else if packages.count == i {
                        button.allowsMixedState = false
                        return .on
                    } else {
                        button.allowsMixedState = true
                        return .mixed
                    }
                }()
                
                button.state = groupState
                cell.textField?.stringValue = name
            }
            
            let bold = [kCTFontAttributeName as NSAttributedStringKey: NSFont.boldSystemFont(ofSize: 13)]
            switch filter {
            case .category:
                // TODO:
                cell.textField?.attributedStringValue = NSAttributedString(string: name, attributes: bold)
            //                cell.textField?.stringValue = header
            case .language:
                let text = ISO639.get(tag: name)?.autonym ?? name
                cell.textField?.attributedStringValue = NSAttributedString(string: text, attributes: bold)
            }
        case let .item(package):
            switch column {
            case .name:
                let button = cell.nextKeyView as! OutlineCheckbox
                
                button.target = self
                button.action = #selector(MainViewControllerDataSource.onCheckboxChanged(_:))
                button.package = package
                button.allowsMixedState = false
                button.isHidden = false
                
                button.toolTip = package.nativeName
                cell.textField?.toolTip = package.nativeName
                
                if let _ = selectedPackages[package.id] {
                    button.state = .on
                } else {
                    button.state = .off
                }
                cell.textField?.stringValue = package.nativeName
            case .version:
                cell.textField?.stringValue = "\(package.version) (\(byteCountFormatter.string(fromByteCount: package.installer.size)))"
            case .state:
                if let selectedPackage = selectedPackages[package.id] {
                    let paraStyle = NSMutableParagraphStyle()
                    paraStyle.alignment = .left
                    
                    let attrs: [NSAttributedStringKey: Any] = [
                        NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 13),
                        NSAttributedStringKey.paragraphStyle: paraStyle
                    ]
                    cell.textField?.attributedStringValue = NSAttributedString(string: selectedPackage.description, attributes: attrs)
                } else {
                    cell.textField?.stringValue = statuses[package.id]!.description
                }
            }
        }
        
        return cell
    }
    
    deinit {
        outlet.onCompleted()
    }
}

