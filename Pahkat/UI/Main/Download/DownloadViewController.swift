//
//  DownloadViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class DownloadViewController: DisposableViewController<DownloadView>, DownloadViewable, NSToolbarDelegate {
    private let byteCountFormatter = ByteCountFormatter()
    private var delegate: DownloadProgressTableDelegate! = nil
    
//    private let actions: [PackageAction]
    
    internal lazy var presenter = { DownloadPresenter(view: self, actions: AppContext.currentActions!) }()

//    init(actions: [PackageAction]) {
//        self.actions = actions
//        super.init()
//    }
    
    required init() {
        // FIXME: none of this TODO
//        self.actions = []
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    var onCancelTapped: Driver<Void> {
//        return self.contentView.primaryButton.rx.tap.asDriver()
//    }
    
    // TODO: maybe get rid of PackageDownloadStatus and use the new RPC one?
    func setStatus(key: PackageKey?, status: PackageDownloadStatus) {
        DispatchQueue.main.async {
            // TODO: waiting for RPC to be our friend
//            if let view = self.delegate.tableView(self.contentView.tableView, viewFor: package) as? DownloadProgressView {
//                switch(status) {
//                case .notStarted:
//                    view.progressLabel.stringValue = Strings.queued
//                case .starting:
//                    view.progressLabel.stringValue = Strings.starting
//                    if let cellOrigin: NSPoint = view.superview?.frame.origin {
//                        self.contentView.clipView.animate(to: cellOrigin, with: 0.5)
//                    }
//                case .progress(let downloaded, let total):
//                    view.progressBar.maxValue = Double(total)
//                    view.progressBar.minValue = 0
//                    view.progressBar.doubleValue = Double(downloaded)
//
//                    let downloadStr = self.byteCountFormatter.string(fromByteCount: Int64(downloaded))
//                    let totalStr = self.byteCountFormatter.string(fromByteCount: Int64(total))
//
//                    view.progressLabel.stringValue = "\(downloadStr) / \(totalStr)"
//                case .completed:
//                    view.progressLabel.stringValue = Strings.completed
//                case .error:
//                    view.progressLabel.stringValue = Strings.downloadError
//                }
//            } else {
//                fatalError("couldn't get downloadProgressView")
//            }
        }
    }
    
    func cancel() {
        DispatchQueue.main.async {
            print("FUNKY CANCEL")
            AppContext.cancelTransactionCallback?().subscribe().disposed(by: self.bag)
            AppContext.cancelTransactionCallback = nil
            AppContext.currentTransaction.onNext(.none)
        }
    }
    
    func startInstallation(transaction: TransactionType) {
//        DispatchQueue.main.async {
//            AppContext.windows.set(
//                InstallViewController(transaction: transaction, repos: self.repos),
//                for: MainWindowController.self)
//        }
        todo()
    }
    
    func handle(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = String(describing: error)
            alert.alertStyle = .critical
            
            log.error(error)
            alert.runModal()
            
            self.cancel()
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "button":
            contentView.primaryButton.title = Strings.cancel
            contentView.primaryButton.sizeToFit()
            return NSToolbarItem(view: contentView.primaryButton, identifier: itemIdentifier)
        case "title":
            contentView.primaryLabel.stringValue = Strings.downloading
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
        title = Strings.downloading
        
        configureToolbar()
    }
    
    func initializeDownloads(packages: [(Descriptor, Release)]) {
        self.delegate = DownloadProgressTableDelegate(with: packages)
        contentView.tableView.delegate = self.delegate
        contentView.tableView.dataSource = self.delegate
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        presenter.start().disposed(by: bag)
    }
}

class DownloadProgressTableDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private var views = [View]()
    private let packages: [(Descriptor, Release)]
    
    init(with packages: [(Descriptor, Release)]) {
        self.packages = packages
        
        for (package, release) in packages {
            let view = DownloadProgressView.loadFromNib()
            let name = package.nativeName
            view.nameLabel.stringValue = "\(name) \(release.nativeVersion)"
            self.views.append(view)
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor package: Descriptor) -> NSView? {
        if let row = packages.map { $0.0 }.firstIndex(of: package) {
            return self.tableView(tableView, viewFor: nil, row: row)
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return views[row]
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return views.count
    }
}

extension NSClipView {
    func animate(to point:NSPoint, with duration:TimeInterval) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        NSAnimationContext.current.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.default)
        self.animator().setBoundsOrigin(point)
        if let scrollView = self.superview as? NSScrollView {
            scrollView.reflectScrolledClipView(self)
        }
        NSAnimationContext.endGrouping()
    }
}
