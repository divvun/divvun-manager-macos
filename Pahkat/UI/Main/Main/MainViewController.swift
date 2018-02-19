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

class MainViewController: DisposableViewController<MainView>, MainViewable {
    private lazy var presenter = { MainPresenter(view: self) }()
    
    var onPackageToggled: Observable<Package> = Observable.empty()
    var onGroupToggled: Observable<[Package]> = Observable.empty()
    
    lazy var onPrimaryButtonPressed: Driver<Void> = {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }()
    
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
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presenter.start().disposed(by: bag)
    }
}
