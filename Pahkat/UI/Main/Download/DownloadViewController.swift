//
//  DownloadViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift

class DownloadViewController: DisposableViewController<DownloadView>, DownloadViewable {
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

