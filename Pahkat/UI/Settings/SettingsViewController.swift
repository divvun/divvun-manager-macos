//
//  SettingsViewController.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa
import PahkatClient

extension Repository.Channels {
    var description: String {
        switch self {
        case .alpha:
            return Strings.alpha
        case .beta:
            return Strings.beta
        case .nightly:
            return Strings.nightly
        case .stable:
            return Strings.stable
        }
    }
}

struct RepositoryTableRowData {
    let name: String?
    let url: URL?
    let channel: Repository.Channels?
}

class SettingsViewController: DisposableViewController<SettingsView>, SettingsViewable, NSWindowDelegate {
    private(set) var tableDelegate: RepositoryTableDelegate! = nil
    private lazy var presenter = { SettingsPresenter(view: self) }()
    
    var onAddRepoButtonTapped: Driver<Void> {
        return contentView.repoAddButton.rx.tap.asDriver()
    }
    
    var onRemoveRepoButtonTapped: Driver<Void> {
        return contentView.repoRemoveButton.rx.tap.asDriver()
    }
    
    func addBlankRepositoryRow() {
        let rows = self.contentView.repoTableView.numberOfRows
        self.contentView.repoTableView.beginUpdates()
        self.tableDelegate.configs.append(RepositoryTableRowData(name: nil, url: nil, channel: .stable))
        self.contentView.repoTableView.insertRows(at: IndexSet(integer: rows), withAnimation: .effectFade)
        self.contentView.repoTableView.endUpdates()
        self.contentView.repoTableView.editColumn(0, row: rows, with: nil, select: true)
    }
    
    func updateProgressIndicator(isEnabled: Bool) {
        DispatchQueue.main.async {
            if isEnabled {
                self.contentView.repoTableView.isHidden = true
                self.contentView.progressIndicator.startAnimation(self)
            } else {
                self.contentView.repoTableView.isHidden = false
                self.contentView.progressIndicator.stopAnimation(self)
            }
        }
    }
    
    func promptRemoveRepositoryRow() {
        let row = self.contentView.repoTableView.selectedRow
        if row < 0 {
            return
        }
        let alert = NSAlert()
        alert.messageText = Strings.removeRepoTitle
        alert.informativeText = Strings.removeRepoBody
        alert.addButton(withTitle: Strings.ok)
        alert.addButton(withTitle: Strings.cancel)
        alert.beginSheetModal(for: self.contentView.window!, completionHandler: {
            if $0 == NSApplication.ModalResponse.alertFirstButtonReturn {
                self.tableDelegate.configs.remove(at: row)
                self.contentView.repoTableView.beginUpdates()
                self.contentView.repoTableView.removeRows(at: IndexSet(integer: row), withAnimation: .effectFade)
                self.contentView.repoTableView.endUpdates()
            }
        })
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let tableDelegate = tableDelegate, let AppContext = AppContext else {
            return
        }
        
        let v = tableDelegate.configs.compactMap { t -> RepoRecord? in
            if let url = t.url, let channel = t.channel {
                return RepoRecord(url: url, channel: channel)
            }
            return nil
        }
        
        AppContext.settings.dispatch(event: .setRepositoryConfigs(v))
    }
    
    func handle(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = error.localizedDescription
            
            alert.alertStyle = .critical
            log.error(error)
            alert.runModal()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppContext.windows.get(SettingsWindowController.self).window!.delegate = self
        
        title = Strings.settings
        
        InterfaceLanguage.bind(to: contentView.languageDropdown.menu!)
        UpdateFrequency.bind(to: contentView.frequencyPopUp.menu!)
        Repository.Channels.bind(to: contentView.repoChannelColumn.menu!)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        // TODO: move to presenter
        contentView.repoAddButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.addBlankRepositoryRow()
        }).disposed(by: bag)
        
        contentView.repoRemoveButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.promptRemoveRepositoryRow()
        }).disposed(by: bag)
        
        AppContext.settings.state.map { $0.interfaceLanguage }
            .subscribe(onNext: { [weak self] language in
                guard let `self` = self else { return }
                
                guard let item = self.contentView.languageDropdown.menu!.items
                    .first(where: { ($0.representedObject as! InterfaceLanguage).rawValue == language }) else {
                    return
                }
                
                self.contentView.languageDropdown.select(item)
            }).disposed(by: bag)
        
        AppContext.settings.state.map { $0.updateCheckInterval }
            .subscribe(onNext: { [weak self] frequency in
                guard let `self` = self else { return }
                
                guard let item = self.contentView.frequencyPopUp.menu!.items
                    .first(where: { ($0.representedObject as! UpdateFrequency) == frequency }) else {
                        return
                }
                
                self.contentView.frequencyPopUp.select(item)
            }).disposed(by: bag)
        
        contentView.languageDropdown.rx.tap
            .map { self.contentView.languageDropdown.selectedItem!.representedObject as! InterfaceLanguage }
            .subscribe(onNext: {
                AppContext.settings.dispatch(event: .setInterfaceLanguage($0.rawValue))
            }).disposed(by: bag)
        
        contentView.frequencyPopUp.rx.tap
            .map { self.contentView.frequencyPopUp.selectedItem!.representedObject as! UpdateFrequency }
            .subscribe(onNext: {
                AppContext.settings.dispatch(event: .setUpdateCheckInterval($0))
            }).disposed(by: bag)
        
        presenter.start().disposed(by: bag)
    }
    
    func setRepositories(repositories: [RepositoryTableRowData]) {
        self.tableDelegate = RepositoryTableDelegate(with: repositories)
        contentView.repoTableView.delegate = self.tableDelegate
        contentView.repoTableView.dataSource = self.tableDelegate
    }
}

enum RepositoryTableColumns: String {
    case url
    case name
    case channel
    
    init?(identifier: NSUserInterfaceItemIdentifier) {
        if let value = RepositoryTableColumns(rawValue: identifier.rawValue) {
            self = value
        } else {
            return nil
        }
    }
}

enum RepositoryTableEvent {
    case setChannel(Int, Repository.Channels)
    case setURL(Int, URL)
    case remove(Int)
}

class RepositoryTableDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    fileprivate var configs: [RepositoryTableRowData]
    fileprivate let events = PublishSubject<RepositoryTableEvent>()
    
    init(with configs: [RepositoryTableRowData]) {
        self.configs = configs
        super.init()
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let tableColumn = tableColumn else { return nil }
        guard let column = RepositoryTableColumns(identifier: tableColumn.identifier) else { return nil }
        
        if row >= configs.count {
            return nil
        }
        
        let config = configs[row]
        
        switch column {
        case .url:
            return config.url?.absoluteString
        case .name:
            return config.name
        case .channel:
            guard let cell = tableColumn.dataCell as? NSPopUpButtonCell else { return nil }
            guard let index = cell.menu?.items.firstIndex(where: {
                $0.representedObject as? Repository.Channels == config.channel
            }) else {
                return nil
            }
            return index
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let tableColumn = tableColumn else { return }
        guard let column = RepositoryTableColumns(identifier: tableColumn.identifier) else { return }
        
        if row >= configs.count {
            return
        }
        
        switch column {
        case .url:
            guard let string = object as? String else { return }
            
            if string == "" {
                return
            }
            
            if let url = URL(string: string), url.scheme?.starts(with: "http") ?? false {
                self.configs[row] = RepositoryTableRowData(name: Strings.loading, url: url, channel: configs[row].channel)
                events.onNext(.setURL(row, url))
            } else {
                let alert = NSAlert()
                alert.messageText = Strings.invalidUrlTitle
                alert.informativeText = Strings.invalidUrlBody
                alert.runModal()
            }
        case .name:
            break
        case .channel:
            guard let cell = tableColumn.dataCell as? NSPopUpButtonCell else { return }
            guard let index = object as? Int else { return }
            guard let menuItem = cell.menu?.item(at: index) else { return }
            guard let channel = menuItem.representedObject as? Repository.Channels else { return }
            
            // Required or UI does a weird blinking thing.
            self.configs[row] = RepositoryTableRowData(name: configs[row].name, url: configs[row].url, channel: channel)
            events.onNext(.setChannel(row, channel))
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.configs.count
    }
}

enum InterfaceLanguage: String, Comparable {
    case systemLocale = ""
    case en = "en"
    case nb = "nb"
    case nn = "nn"
    case nnRunic = "nn-Runr"
    case se = "se"
    
    var description: String {
        if self == .systemLocale {
            return Strings.systemLocale
        }
        
        if self == .nnRunic {
            return "ᚿᛦᚿᚮᚱᛌᚴ"
        }
        
        return ISO639.get(tag: self.rawValue)?.autonymOrName ?? self.rawValue
    }
    
    static func <(lhs: InterfaceLanguage, rhs: InterfaceLanguage) -> Bool {
        return lhs.description < rhs.description
    }
    
    private static func createMenuItem(_ thingo: InterfaceLanguage) -> NSMenuItem {
        return NSMenuItem(title: thingo.description, value: thingo)
    }
    
    static func asMenuItems() -> [NSMenuItem] {
        var x = [
            InterfaceLanguage.en,
            InterfaceLanguage.nb,
            InterfaceLanguage.nn,
            InterfaceLanguage.nnRunic,
            InterfaceLanguage.se
        ].sorted()
        
        x.insert(InterfaceLanguage.systemLocale, at: 0)
        
        return x.map { createMenuItem($0) }
    }
    
    static func bind(to menu: NSMenu) {
        self.asMenuItems().forEach(menu.addItem(_:))
    }
}

fileprivate extension UpdateFrequency {
    private static func createMenuItem(_ thingo: UpdateFrequency) -> NSMenuItem {
        return NSMenuItem(title: thingo.description, value: thingo)
    }
    
    static func asMenuItems() -> [NSMenuItem] {
        return [
            UpdateFrequency.createMenuItem(.daily),
            UpdateFrequency.createMenuItem(.weekly),
            UpdateFrequency.createMenuItem(.fortnightly),
            UpdateFrequency.createMenuItem(.monthly),
            UpdateFrequency.createMenuItem(.never)
        ]
    }
    
    static func bind(to menu: NSMenu) {
        self.asMenuItems().forEach(menu.addItem(_:))
    }
}

fileprivate extension Repository.Channels {
    private static func createMenuItem(_ thingo: Repository.Channels) -> NSMenuItem {
        return NSMenuItem(title: thingo.description, value: thingo)
    }
    
    static func asMenuItems() -> [NSMenuItem] {
        return [
            createMenuItem(.stable),
            createMenuItem(.alpha),
            createMenuItem(.beta),
            createMenuItem(.nightly),
        ]
    }
    
    static func bind(to menu: NSMenu) {
        self.asMenuItems().forEach(menu.addItem(_:))
    }
}


