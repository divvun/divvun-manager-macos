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

class InstallViewController: DisposableViewController<InstallView>, InstallViewable {
    func setStarting(package: Package) {
        print("Starting package")
        DispatchQueue.main.async {
            self.contentView.nameLabel.stringValue = "Installing \(package.name[Strings.languageCode ?? "en"] ?? "") \(package.version)…"
        }
    }
    
    func setEnding(package: Package) {
        DispatchQueue.main.async {
            self.contentView.horizontalIndicator.increment(by: 1.0)
        }
    }
    
    private let packages: [Package]
    private lazy var presenter = { InstallPresenter(view: self, packages: packages) }()
    
    init(packages: [Package]) {
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
}
