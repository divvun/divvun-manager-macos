//
//  UpdateViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class UpdateViewController: DisposableViewController<UpdateView>, UpdateViewable {
    internal lazy var presenter = { UpdatePresenter(view: self) }()
    private var tableDelegate: UpdateTableDelegate! = nil
    
    lazy var onSkipButtonPressed: Driver<Void> = {
        return self.contentView.skipButton.rx.tap.asDriver()
    }()
    
    lazy var onInstallButtonPressed: Driver<Void> = {
        return self.contentView.installButton.rx.tap.asDriver()
    }()
    
    lazy var onRemindButtonPressed: Driver<Void> = {
        return self.contentView.remindButton.rx.tap.asDriver()
    }()
    
    lazy var onPackageToggled: Observable<UpdateTablePackage> = {
        self.tableDelegate.events.asObservable()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.updateAvailable
        
        self.tableDelegate = UpdateTableDelegate(with: [])
        self.contentView.tableView.dataSource = self.tableDelegate
        self.contentView.tableView.delegate = self.tableDelegate
        
//        AppContext.settings.state.map { $0.repositories }
//            .flatMapLatest { (configs: [RepoConfig]) -> Observable<[RepositoryIndex]> in
//                return try AppDelegate.instance.requestRepos(configs)
//            }
//            .observeOn(MainScheduler.instance)
//            .subscribeOn(MainScheduler.instance)
//            .subscribe(onNext: { repos in
//                print("Refreshed repos in main view.")
//                AppContext.store.dispatch(event: AppEvent.setRepositories(repos))
//            }, onError: { _ in
//                // Do nothing.
//            })
//            .disposed(by: bag)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presenter.start().disposed(by: bag)
        
        contentView.packageHelpTitle.stringValue = Strings.wouldYouLikeToDownloadThemNow
        
        contentView.installButton.title = Strings.noPackagesSelected
        contentView.installButton.isEnabled = false
        contentView.skipButton.title = Strings.skipTheseUpdates
        contentView.remindButton.title = Strings.remindMeLater
        
        contentView.installButton.sizeToFit()
        contentView.skipButton.sizeToFit()
        contentView.remindButton.sizeToFit()
    }
    
    func closeWindow() {
        AppContext.windows.close(UpdateWindowController.self)
    }
    
    func installPackages(packages: [AbsolutePackageKey: PackageAction]) {
        AppContext.windows.show(MainWindowController.self, viewController: DownloadViewController(packages: packages))
        AppDelegate.instance.requiresAppDeath = false
        closeWindow()
    }
    
    func setPackages(packages: [UpdateTablePackage]) {
        self.contentView.packageCountTitle.stringValue = Strings.thereAreNUpdatesAvailable(count: String(packages.count))
        
        self.tableDelegate.packages = packages
        self.contentView.tableView.reloadData()
        
        let selected = packages.reduce(0, { (acc, cur) in cur.isEnabled ? acc + 1 : acc })
        
        if (selected > 0) {
            contentView.installButton.title = Strings.installNPackages(count: String(selected))
            contentView.installButton.isEnabled = true
        } else {
            contentView.installButton.title = Strings.noPackagesSelected
            contentView.installButton.isEnabled = false
        }
        
        contentView.installButton.sizeToFit()
    }
}

enum UpdateViewTableColumns: String {
    case name = "name"
    case version = "version"
    
    init?(identifier: NSUserInterfaceItemIdentifier){
        if let value = UpdateViewTableColumns(rawValue: identifier.rawValue) {
            self = value
        } else {
            return nil
        }
    }
}

class UpdateTableCheckbox: NSButton {
    var package: UpdateTablePackage?
}

struct UpdateTablePackage: Equatable, Comparable {
    let package: Package
    let action: PackageAction
    var isEnabled: Bool
    
    static func ==(lhs: UpdateTablePackage, rhs: UpdateTablePackage) -> Bool {
        return lhs.package == rhs.package && lhs.action == rhs.action
    }
    
    static func <(lhs: UpdateTablePackage, rhs: UpdateTablePackage) -> Bool {
        if lhs.package.nativeName == rhs.package.nativeName {
            return lhs.package.hashValue < rhs.package.hashValue
        }
        
        return lhs.package.nativeName < rhs.package.nativeName
    }
}

class UpdateTableDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    fileprivate var packages: [UpdateTablePackage]
    private let byteCountFormatter = ByteCountFormatter()
    let events = PublishSubject<UpdateTablePackage>()
    
    init(with packages: [UpdateTablePackage]) {
        self.packages = packages
        
        super.init()
    }
    
    @objc func onCheckboxChanged(_ sender: Any) {
        guard let button = sender as? UpdateTableCheckbox else { return }
        
        if let package = button.package {
            self.events.onNext(package)
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        guard let column = UpdateViewTableColumns(identifier: tableColumn.identifier) else { return nil }
        let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        let package = packages[row]
        switch column {
        case .name:
            let packageName = package.package.nativeName
            cell.textField?.stringValue =  packageName

            if let button = cell.nextKeyView as? UpdateTableCheckbox {
                button.target = self
                button.action = #selector(UpdateTableDelegate.onCheckboxChanged(_:))
                button.package = package
                
                if package.isEnabled {
                    button.state = .on
                } else {
                    button.state = .off
                }
            }
        case .version:
            let version = package.package.version
            var size: String = self.byteCountFormatter.string(fromByteCount: 0)
            switch package.package.installer {
            case .macOsInstaller(let installer):
                size = self.byteCountFormatter.string(fromByteCount: Int64(installer.size))
            default:
                break
            }
            cell.textField?.stringValue = Strings.updateAvailable + ": " + version + " (" + size + ")"
        }


        return cell
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return packages.count
    }
    
    deinit {
        events.onCompleted()
    }
}
