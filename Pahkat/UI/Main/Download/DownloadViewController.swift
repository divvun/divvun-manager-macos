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

class DownloadViewController: DisposableViewController<DownloadView>, DownloadViewable {
    
    private var delegate: DownloadProgressTableDelegate! = nil
    var onCancelTapped: Driver<Void>{
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
                    view.progressLabel.stringValue = "Not Started"
                case .starting:
                    view.progressLabel.stringValue = "Starting…"
                case .progress(let downloaded, let total):
                    view.progressBar.maxValue = Double(total)
                    view.progressBar.minValue = 0
                    view.progressBar.doubleValue = Double(downloaded)
                    view.progressLabel.stringValue = "Downloading…"
                case .completed:
                    view.progressLabel.stringValue = "Completed"
                case .error:
                    view.progressLabel.stringValue = "Error"
                }
            } else {
                print("couldn't get downloadProgressView")
            }
        }
    }
    
    func cancel() {
        print("cancel")
    }
    
    func startInstallation(packages: [Package]) {
        AppContext.windows.set(InstallViewController(packages: packages), for: MainWindowController.self)
    }
    
    func handle(error: Error) {
        print(error)
    }
    
    private let packages: [Package]
    internal lazy var presenter = { DownloadPresenter(view: self, packages: packages) }()
    
    init(packages: [Package]) {
        self.packages = packages
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = Strings.downloading
        
        self.delegate = DownloadProgressTableDelegate.init(withPackages: packages)
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
    private var packages = [Package]()
    
    init(withPackages packages:[Package]) {
        for package in packages {
            let view = DownloadProgressView.loadFromNib()
            view.nameLabel.stringValue = package.name[Strings.languageCode ?? "en"] ?? ""
            view.versionLabel.stringValue = package.version
            self.views.append(view)
            self.packages.append(package)
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

