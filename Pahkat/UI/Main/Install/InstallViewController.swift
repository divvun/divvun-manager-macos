//
//  InstallViewController.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-19.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class InstallViewController: DisposableViewController<InstallView>, InstallViewable, NSToolbarDelegate {
    private let packages: [URL: PackageAction]
    private lazy var presenter = { InstallPresenter(view: self, packages: packages) }()
    private var cancelToken: CancelToken? = nil
    
    var onCancelTapped: Driver<Void> {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }
    
    init(packages: [URL: PackageAction]) {
        self.packages = packages
        super.init()
    }
    
    private func setRemaining() {
        // Shhhhh
        let max = Int(self.contentView.horizontalIndicator.maxValue)
        let value = Int(self.contentView.horizontalIndicator.doubleValue)
        
        self.contentView.remainingLabel.stringValue = Strings.nItemsRemaining(count: String(max - value))
    }
    
    func setStarting(action: PackageAction) {
        DispatchQueue.main.async {
            let label: String
            
            switch action {
            case let .install(_, record, _):
                label = Strings.installingPackage(name: record.package.nativeName, version: record.package.version)
            case let .uninstall(_, record, _):
                label = Strings.uninstallingPackage(name: record.package.nativeName, version: record.package.version)
            }
            
            self.contentView.nameLabel.stringValue = label
            self.setRemaining()
        }
    }
    
    func setEnding(action: PackageAction) {
        DispatchQueue.main.async {
            self.contentView.horizontalIndicator.increment(by: 1.0)
            self.setRemaining()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(totalPackages total: Int) {
        contentView.horizontalIndicator.maxValue = Double(total)
        
        if (total == 1) {
            contentView.horizontalIndicator.isIndeterminate = true
            contentView.horizontalIndicator.startAnimation(self)
        }
    }
    
    func showCompletion() {
        AppContext.windows.set(CompletionViewController(with: self.packages), for: MainWindowController.self)
    }
    
    func handle(error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: Strings.ok)
        alert.messageText = Strings.errorDuringInstallation
        
        if let error = error as? JSONRPCError {
            alert.informativeText = error.message
        } else {
            alert.informativeText = error.localizedDescription
        }
        
        alert.runModal()
        
        AppContext.windows.set(MainViewController(), for: MainWindowController.self)
    }
    
    func beginCancellation() {
        contentView.primaryButton.isEnabled = false
        contentView.primaryButton.title = Strings.cancelling
        cancelToken?.cancel()
    }
    
    func processCancelled() {
        AppContext.windows.set(MainViewController(), for: MainWindowController.self)
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "button":
            contentView.primaryButton.title = Strings.cancel
            contentView.primaryButton.sizeToFit()
            return NSToolbarItem(view: contentView.primaryButton, identifier: itemIdentifier)
        case "title":
            contentView.primaryLabel.stringValue = Strings.installingUninstalling
            contentView.primaryLabel.sizeToFit()
            return NSToolbarItem(view: contentView.primaryLabel, identifier: itemIdentifier)
        default:
            return nil
        }
    }
    
    private func configureToolbar() {
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        
        window.titleVisibility = .hidden
        window.toolbar!.isVisible = true
        window.toolbar!.delegate = self
        
        let toolbarItems = [NSToolbarItem.Identifier.flexibleSpace.rawValue,
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
        self.presenter.start().disposed(by: bag)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        cancelToken = self.presenter.install()
    }
}
