import Cocoa
import RxSwift
import RxCocoa



class MainViewController: DisposableViewController<MainView>, MainViewable, NSToolbarDelegate {
    required init() {
        log.debug("MAIN INIT")
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        log.debug("MAIN DEINIT")
    }
    
    func setRepositories(data: MainOutlineMap) {
        assert(Thread.isMainThread)

        dataSource.repos = data
        
        contentView.outlineView.reloadData()
        self.contentView.outlineView.expandItem(nil, expandChildren: true)
        
        // This forces resizing to work correctly.
        self.refreshRepositories()
    }
    
    func refreshRepositories() {
        assert(Thread.isMainThread)

        let contentView = self.contentView
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
        assert(Thread.isMainThread)

        DispatchQueue.main.async {
            if isEnabled {
                self.contentView.progressIndicator.startAnimation(self)
            } else {
                self.contentView.progressIndicator.stopAnimation(self)
            }
        }
    }
    
    func showSettings() {
        assert(Thread.isMainThread)
        AppContext.windows.show(SettingsWindowController.self)
    }

    func repositoriesChanged(repos: [LoadedRepository], records: [URL : RepoRecord]) {
        assert(Thread.isMainThread)
        let repos = repos.filter { records[$0.index.url] != nil }

        let popupButton = contentView.popupButton

        popupButton.removeAllItems()
        repos.filter { $0.index.landingURL != nil }.forEach { (repo) in
            let name = repo.index.nativeName
            let url = repo.index.url
            let menuItem = NSMenuItem(title: name)
            menuItem.representedObject = url
            popupButton.menu?.addItem(menuItem)
        }

        popupButton.menu?.addItem(NSMenuItem.separator())

        let showDetailedItem = NSMenuItem(title: Strings.allRepositories)
        showDetailedItem.representedObject = URL(string: "divvun-manager:detailed")
        popupButton.menu?.addItem(showDetailedItem)
        popupButton.select(showDetailedItem)

        popupButton.action = #selector(self.popupItemSelected)
        popupButton.target = self
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
        assert(Thread.isMainThread)
        DispatchQueue.main.async {
            self.contentView.settingsButton.isEnabled = isEnabled
        }
    }
    
    func updatePrimaryButton(isEnabled: Bool, label: String) {
        assert(Thread.isMainThread)
        contentView.primaryButton.isEnabled = isEnabled
        contentView.primaryButton.title = label
        
        contentView.primaryButton.sizeToFit()
        contentView.primaryLabel.sizeToFit()
        
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        window.toolbar!.redraw()
    }
    
    func handle(error: Error) {
        log.debug(Thread.callStackSymbols.joined(separator: "\n"))
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
        case "repo-selector":
            return NSToolbarItem.init(view: contentView.popupButton, identifier: itemIdentifier)
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
//                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
//                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "repo-selector",
//                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "button"]
        
        window.toolbar!.setItems(toolbarItems)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        configureToolbar()
        
        dataSource.events.subscribe(onNext: { [weak self] value in
            self?.onPackageEventSubject.onNext(value)
        }).disposed(by: bag)

        contentView.outlineView.delegate = self.dataSource
        contentView.outlineView.dataSource = self.dataSource
        
        contentView.outlineView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        
        self.update(title: Strings.appName)
        updatePrimaryButton(isEnabled: false, label: Strings.noPackagesSelected)
        
        presenter.start().disposed(by: bag)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        log.debug("CLEARING MAIN BAG")
        self.bag = DisposeBag()
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        contentView.outlineView.sizeLastColumnToFit()
    }

    @objc func popupItemSelected() {
        guard let url = contentView.popupButton.selectedItem?.representedObject as? URL else {
            log.debug("Selected item has no associated URL")
            return
        }
        DispatchQueue.main.async {
            do {
                try AppContext.settings.write(key: .selectedRepository, value: url)
            } catch {
                log.debug("Error setting selected repo: \(error)")
            }
        }
    }
}

enum OutlineContextMenuItem {
    case selectedPackage(SelectedPackage)
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
            case let .selectedPackage(action):
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
                    menu.addItem(makeMenuItem(Strings.installSystem, value: OutlineContextMenuItem.selectedPackage(v)))
                }
//                if installer.targets.contains(.user) {
//                    let v = SelectedPackage(key: key, package: package, action: .install, target: .user)
//                    menu.addItem(makeMenuItem(Strings.installUser, value: OutlineContextMenuItem.SelectedPackage(v)))
//                }
            case .requiresUpdate:
                let v = SelectedPackage(key: key, package: package, action: .install, target: target)
                menu.addItem(makeMenuItem(Strings.update, value: OutlineContextMenuItem.selectedPackage(v)))
            default:
                break
            }
            
            switch status {
            case .upToDate, .requiresUpdate:
                let v = SelectedPackage(key: key, package: package, action: .uninstall, target: target)
                menu.addItem(makeMenuItem(Strings.uninstall, value: OutlineContextMenuItem.selectedPackage(v)))
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

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        // Fix UI glitch where text is written over previous table row's viewbox.
        return NSTableRowView()
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        guard let column = MainViewOutlineColumns(identifier: tableColumn.identifier) else { return nil }
        let cell = outlineView.makeView(withIdentifier: tableColumn.identifier, owner: nil) as! NSTableCellView

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
                let attrString = NSAttributedString(
                    string: "\(item.release.version) (\(byteCountFormatter.string(fromByteCount: size)))",
                    attributes: [NSAttributedString.Key.kern: -0.75])

                cell.textField?.attributedStringValue = attrString
                let a = (cell.textField?.attributedStringValue.size().width ?? CGFloat(0.0)) * 1.35

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
        
        // Offset textfield if checkbox is visible
        if let checkbox = cell.nextKeyView as? OutlineCheckbox, let c = checkbox.constraints.first(where: { x in x.firstAttribute == .width }) {
            if checkbox.isHidden {
                c.constant = 0.0
            } else {
                c.constant = 12.0
            }
        }

        return cell
    }
    
    deinit {
        events.onCompleted()
    }
}

