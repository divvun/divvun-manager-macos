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

extension Package {
    var nativeName: String {
        return self.name[Strings.languageCode ?? "en"] ?? ""
    }
}

class InstallViewController: DisposableViewController<InstallView>, InstallViewable {
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
            case let .install(package):
                label = Strings.installingPackage(name: package.nativeName, version: package.version)
            case let .uninstall(package):
                label = Strings.uninstallingPackage(name: package.nativeName, version: package.version)
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
    
    private let packages: [String: PackageAction]
    private lazy var presenter = { InstallPresenter(view: self, packages: packages) }()
    
    init(packages: [String: PackageAction]) {
        self.packages = packages
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onCancelTapped: Observable<Void> = Observable.empty()
    
    func set(currentPackage info: OnStartPackageInfo) {
        
    }
    
    func set(totalPackages total: Int) {
        print("Settings total packages")
        if (total == 1) {
            contentView.horizontalIndicator.isIndeterminate = true
            contentView.horizontalIndicator.startAnimation(self)
        } else {
            contentView.horizontalIndicator.maxValue = Double(total)
        }
    }
    
    func showCompletion(isCancelled: Bool, results: [ProcessResult]) {
    }
    
    func handle(error: Error) {
        
    }
    
    func processCancelled() {
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.presenter.start().disposed(by: bag)
    }
}
