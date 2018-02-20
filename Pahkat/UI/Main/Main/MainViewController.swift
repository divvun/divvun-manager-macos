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
    
    private var dataSource: MainViewControllerDataSource! = nil
    
    let onPackagesToggledSubject = PublishSubject<[Package]>()
    var onPackagesToggled: Observable<[Package]> {
        return onPackagesToggledSubject.asObservable()
    }
    var onGroupToggled: Observable<[Package]> = Observable.empty()
    
    lazy var onPrimaryButtonPressed: Driver<Void> = {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }()
    
    func setRepository(repo: RepositoryIndex, statuses: [String: PackageInstallStatus]) {
        //print(repo)
        self.repo = repo
        dataSource = MainViewControllerDataSource(with: repo, statuses: statuses, filter: repo.meta.primaryFilter, outlet: onPackagesToggledSubject)
        contentView.outlineView.delegate = self.dataSource
        contentView.outlineView.dataSource = self.dataSource
    }
    
    func update(title: String) {
        self.title = title
    }
    
    func showDownloadView(with packages: [Package]) {
        AppContext.windows.set(DownloadViewController(packages: packages), for: MainWindowController.self)
    }
    
    func updatePrimaryButton(isEnabled: Bool, label: String) {
        contentView.primaryButton.isEnabled = isEnabled
        contentView.primaryButton.title = label
    }
    
    func handle(error: Error) {
        print(error)
        // TODO: show errors in a meaningful way to the user
        fatalError("Not implemented")
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == NSToolbarItem.Identifier(rawValue: "button") {
            let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(rawValue: "button"))
            item.label = "Hello"
            item.view = contentView.primaryButton
            return item
        } else if itemIdentifier == NSToolbarItem.Identifier(rawValue: "title") {
            let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(rawValue: "title"))
            let button = contentView.primaryLabel
//            self.bind(.title, to: contentView.primaryLabel, withKeyPath: "stringValue", options: nil)
            item.view = button
            return item
        }
        
        return nil
    }
    
    func updateSelectedPackages(packages: Set<Package>) {
        self.dataSource.selectedPackages = packages
        // TODO: handle race condition with animation of checkboxes, because you chose to do this contract. You idiot.
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            print("PEW PEW PEW")
            self.contentView.outlineView.reloadData()
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        window.titleVisibility = .hidden
        
        window.toolbar!.delegate = self
        window.toolbar!.insertItem(withItemIdentifier: NSToolbarItem.Identifier(rawValue: "title"), at: 1)
        window.toolbar!.insertItem(withItemIdentifier: NSToolbarItem.Identifier(rawValue: "button"), at: 3)
        
        contentView.primaryLabel.stringValue = Strings.appName
        contentView.primaryLabel.sizeToFit()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
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

fileprivate let DIRTY = UnsafeMutableRawPointer.allocate(bytes: 1, alignedTo: 0)

class MainViewControllerDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    let bag = DisposeBag()
    
    private let outlet: PublishSubject<[Package]>
    
    private let data: PackageMap
    private let statuses: [String: PackageInstallStatus]
    private let filter: Repository.PrimaryFilter
    var selectedPackages = Set<Package>()
    
    private let byteCountFormatter = ByteCountFormatter()
    
    init(with repo: RepositoryIndex, statuses: [String: PackageInstallStatus], filter: Repository.PrimaryFilter, outlet: PublishSubject<[Package]>) {
        switch filter {
        //case .category:
        default:
            self.data = categoryFilter(repo: repo)
        //case .language:
        //    self.data = languageFilter(repo: repo)
        }
        
        self.statuses = statuses
        self.filter = filter
        self.outlet = outlet
        
        super.init()
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? String {
            return data[item]!.count
        } else if item is Package {
            return 0
        }
        
        return data.keys.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is String
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? String {
            return data[item]![index]
        } else {
            let keyIndex = data.keys.index(data.keys.startIndex, offsetBy: index)
            return String(data.keys[keyIndex])
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        guard let column = MainViewOutlineColumns(identifier: tableColumn.identifier) else { return nil }
        let cell = outlineView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        
        if let package = item as? Package {
            switch column {
            case .name:
                let packageName = package.name[Strings.languageCode ?? "en"] ?? ""
                cell.textField?.stringValue = packageName
                if let button = cell.nextKeyView as? RxCheckbox {
                    button.set(onToggle: { [weak self] _ in
                        self?.outlet.onNext([package])
                    })
                    button.toolTip = packageName
                    button.state = selectedPackages.contains(package) ? .on : .off
                } else {
                    print("could not get button")
                }
            case .version:
                cell.textField?.stringValue = "\(package.version) (\(byteCountFormatter.string(fromByteCount: package.installer.size)))"
            case .state:
                cell.textField?.stringValue = statuses[package.id]!.description
            }
        } else if let header = item as? String {
            guard case .name = column else { return cell }
            
            if let button = cell.nextKeyView as? RxCheckbox {
                button.set(onToggle: { [weak self] _ in
                    guard let `self` = self else { return }
                    print(self.data[header]!.count)
                    self.outlet.onNext(self.data[header]!)
                })
                button.toolTip = header
                button.state = {
                    for index in 0..<outlineView.numberOfChildren(ofItem: header) {
                        let child = outlineView.child(index, ofItem: header)!
                        let view = self.outlineView(outlineView, viewFor: tableColumn, item: child) as? NSTableCellView
                        if let button = view?.nextKeyView as? NSButton {
                            if(button.state == .on) {
                                return .on
                            }
                        }
                    }
                    return NSControl.StateValue.off
                }()
            } else {
                print("could not get button")
            }
            
            
            
            let bold = [kCTFontAttributeName as NSAttributedStringKey: NSFont.boldSystemFont(ofSize: 13)]
            switch filter {
            case .category:
                // TODO:
                cell.textField?.attributedStringValue = NSAttributedString(string: header, attributes: bold)
//                cell.textField?.stringValue = header
            case .language:
                let text = ISO639.get(tag: header)?.autonym ?? header
                cell.textField?.attributedStringValue = NSAttributedString(string: text, attributes: bold)
            }
        }
        
        return cell
    }
    
    deinit {
        outlet.onCompleted()
    }
    
//    private func outlineView(didCollapse outlineView: NSOutlineView, withKey key: String) {
//        for index in 0..<outlineView.numberOfChildren(ofItem: key) {
//            let child = outlineView.child(index, ofItem: key)!
//            let view = self.outlineView(outlineView, viewFor: tableColumn, item: child) as? NSTableCellView
//            view?.textField?.stringValue="This View"
//            if let button = view?.nextKeyView as? NSButton {
//                button.setNextState()
//                button.isEnabled = false
//                //print(button.title)
//            } else {
//                print("could not find button")
//            }
//        }
//        button.rx.state.changed
//            .observeOn(MainScheduler.instance)
//            .subscribeOn(MainScheduler.instance)
//            .subscribe(onNext: { _ in
//                print(outlineView.numberOfChildren(ofItem: item))
//
//            })
//            .disposed(by: bag)
//
//    }
//
//    func outlineViewItemDidCollapse(_ notification: Notification) {
//        if let view = notification.object as? NSOutlineView, let key = notification.userInfo?["NSObject"] as? String {
//            outlineView(didCollapse: view, withKey: key)
//        }
//    }
}

