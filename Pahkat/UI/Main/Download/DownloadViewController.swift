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
    
    private let packages: [URL: PackageAction]
    internal lazy var presenter = { DownloadPresenter(view: self, packages: packages) }()
    
    init(packages: [URL: PackageAction]) {
        self.packages = packages
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onCancelTapped: Driver<Void> {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }
    
    func setStatus(package: Package, status: PackageDownloadStatus) {
        //print(package)
        print(status)
        // TODO make this main thread and also have good strings (localise).
        DispatchQueue.main.async {
            if let view = self.delegate.tableView(self.contentView.tableView, viewFor: package) as? DownloadProgressView {
                switch(status) {
                case .notStarted:
                    view.progressLabel.stringValue = "Queued"
                case .starting:
                    view.progressLabel.stringValue = "Starting…"
                    if let cellOrigin: NSPoint = view.superview?.frame.origin {
                        self.contentView.clipView.animate(to: cellOrigin, with: 0.5)
                    }
                case .progress(let downloaded, let total):
                    view.progressBar.maxValue = Double(total)
                    view.progressBar.minValue = 0
                    view.progressBar.doubleValue = Double(downloaded)
                    
                    let downloadStr = self.byteCountFormatter.string(fromByteCount: Int64(downloaded))
                    let totalStr = self.byteCountFormatter.string(fromByteCount: Int64(total))
                    
                    view.progressLabel.stringValue = "\(downloadStr) / \(totalStr)"
                case .completed:
                    view.progressLabel.stringValue = "Completed"
                case .error:
                    view.progressLabel.stringValue = Strings.downloadError
                }
            } else {
                print("couldn't get downloadProgressView")
            }
        }
    }
    
    func cancel() {
        AppContext.windows.set(MainViewController(), for: MainWindowController.self)
    }
    
    func startInstallation(packages: [URL: PackageAction]) {
        DispatchQueue.main.async {
            AppContext.windows.set(InstallViewController(packages: packages), for: MainWindowController.self)
        }
    }
    
    func handle(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
            
            print(error)
            
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
        //window.contentWindow.toolbar = nil
    }
    
    func initializeDownloads(packages: [Package]) {
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
    private let packages: [Package]
    
    init(with packages: [Package]) {
        self.packages = packages
        
        for package in packages {
            let view = DownloadProgressView.loadFromNib()
            let name = package.nativeName
            view.nameLabel.stringValue = "\(name) \(package.version)"
            self.views.append(view)
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor package: Package) -> NSView? {
        if let row = packages.index(of: package) {
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
        NSAnimationContext.current.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionDefault)
        self.animator().setBoundsOrigin(point)
        if let scrollView = self.superview as? NSScrollView {
            scrollView.reflectScrolledClipView(self)
        }
        NSAnimationContext.endGrouping()
    }
}
