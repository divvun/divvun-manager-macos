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
    var onCancelTapped: Driver<Void>{
        return self.contentView.primaryButton.rx.tap.asDriver()
    }
    
    func setStatus(package: Package, status: PackageDownloadStatus) {
        print(package)
        print(status)
    }
    
    func cancel() {
        print("cancel")
    }
    
    func startInstallation(packages: [Package]) {
        print(packages)
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
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presenter.start().disposed(by: bag)
    }
}

