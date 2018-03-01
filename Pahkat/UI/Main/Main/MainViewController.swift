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
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        contentView.primaryLabel.stringValue = Strings.appName
        updatePrimaryButton(isEnabled: false, label: Strings.noPackagesSelected)
        
        presenter.start().disposed(by: bag)
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

class OutlineGroup: Equatable, Comparable {
    let id: String
    let value: String
    let filter: Repository.PrimaryFilter
    
    init(id: String, value: String, filter: Repository.PrimaryFilter) {
        self.id = id
        self.value = value
        self.filter = filter
    }
    
    static func ==(lhs: OutlineGroup, rhs: OutlineGroup) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value && lhs.filter == rhs.filter
    }
    
    static func <(lhs: OutlineGroup, rhs: OutlineGroup) -> Bool {
        return lhs.value < rhs.value
    }
}

class OutlinePackage: Equatable {
    let package: Package
    var action: PackageAction?
    
    init(package: Package, action: PackageAction?) {
        self.package = package
        self.action = action
    }
    
    static func ==(lhs: OutlinePackage, rhs: OutlinePackage) -> Bool {
        return lhs.package == rhs.package && lhs.action == rhs.action
    }
}

enum OutlineItem: Equatable {
    case repository(OutlineRepository)
    case group(OutlineGroup, OutlineRepository)
    case item(OutlinePackage, RepositoryIndex)
    
    static func ==(lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        switch (lhs, rhs) {
        case let (.repository(a), .repository(b)):
            return a == b
        case let (.group(a, ar), .group(b, br)):
            return a == b && ar == br
        case let (.item(a, ar), .item(b, br)):
            return a == b && ar == br
        default:
            return false
        }
    }
}

enum OutlineEvent {
    case setPackageAction(PackageAction)
    case togglePackage(RepositoryIndex, Package)
    case toggleGroup(OutlineRepository, OutlineGroup)
    case changeFilter(RepositoryIndex, OutlineGroup, Repository.PrimaryFilter)
}
class OutlineCheckbox: NSButton {
    var event: OutlineEvent?
}


class OutlineRepository: Equatable, Comparable {
    let filter: Repository.PrimaryFilter
    let repo: RepositoryIndex
    
    init(filter: Repository.PrimaryFilter, repo: RepositoryIndex) {
        self.filter = filter
        self.repo = repo
    }
    
    static func ==(lhs: OutlineRepository, rhs: OutlineRepository) -> Bool {
        return lhs.repo == rhs.repo
    }
    
    static func <(lhs: OutlineRepository, rhs: OutlineRepository) -> Bool {
        return lhs.repo < rhs.repo
    }
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
        
//        if let value = item.representedObject as? Repository.PrimaryFilter {
//            filter = value
//            return
//        }
        
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
        case let .item(item, repo):
            guard let status = repo.status(for: item.package)?.status else { return nil }
            guard case let .macOsInstaller(installer) = item.package.installer else { fatalError() }
            
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
    
//    private func set(filter: Repository.PrimaryFilter, for repo: RepositoryIndex) {
//        switch filter {
//        case .category:
//            self.data = categoryFilter(repo: repo)
//            self.orderedDataKeys = self.data.keys.sorted().map { ($0, $0) }
//        case .language:
//            self.data = languageFilter(repo: repo)
//            self.orderedDataKeys = self.data.keys.sorted().map { (ISO639.get(tag: $0)?.autonym ?? ISO639.get(tag: $0)?.name ?? $0, $0) }
//        }
//    }
    
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
            
            return OutlineItem.item(x[index], repo.repo)
        default: // number of repositories
            fatalError()
        }
    }
    
    @objc func onCheckboxChanged(_ sender: Any) {
        guard let button = sender as? OutlineCheckbox else { return }
        
        if let event = button.event {
            self.events.onNext(event)
        }
        
//        if let package = button.package {
//            self.events.onNext(OutlineEvent.togglePackage(button., <#T##Package#>))
//            self.outlet.onNext([package])
//        } else if let group = button.group, let packages = data[group] {
//            let toggleIds = Set(selectedPackages.keys).intersection(packages.map { $0.id })
//            let x = toggleIds.count > 0 ? toggleIds.map { id in packages.first(where: { id == $0.id })! } : packages
//            self.outlet.onNext(x)
//        }
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
            let repo = outlineRepo.repo
            let name = group.value
            let id = group.id
            let filter = group.filter
            
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
        case let .item(item, repo):
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
                    
                    let attrs: [NSAttributedStringKey: Any] = [
                        NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 13),
                        NSAttributedStringKey.paragraphStyle: paraStyle
                    ]
                    cell.textField?.attributedStringValue = NSAttributedString(string: selectedPackage.description, attributes: attrs)
                } else {
                    cell.textField?.stringValue = repo.status(for: item.package)?.status.description ?? Strings.downloadError
                }
            }
        }
        
        return cell
    }
    
    deinit {
        events.onCompleted()
    }
}

