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

class MainViewController: ViewController<MainView>, MainViewable {
    private var bag = DisposeBag()
    private var presenter: MainPresenter!
    
    var onPackageToggled: Observable<Package> = Observable.empty()
    
    var onGroupToggled: Observable<[Package]> = Observable.empty()
    
    lazy var onPrimaryButtonPressed: Driver<Void> = {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }()
    
    func update(title: String) {
        self.title = title
    }
    
    func showDownloadView() {
        fatalError("Not implemented")
    }
    
    func updatePrimaryButton(isEnabled: Bool, label: String) {
        contentView.primaryButton.isEnabled = isEnabled
        contentView.primaryButton.title = label
    }
    
    func handle(error: Error) {
        print(error)
        fatalError("Not implemented")
    }
    
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MainPresenter(view: self)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presenter.start().disposed(by: bag)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        bag = DisposeBag()
    }
}
