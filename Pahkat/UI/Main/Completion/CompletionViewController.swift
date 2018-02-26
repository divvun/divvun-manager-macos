//
//  CompletionViewController.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-19.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class CompletionViewController: DisposableViewController<CompletionView>, CompletionViewable {
//        
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    
    var onRestartButtonTapped: Observable<Void> = Observable.empty()
    var onFinishButtonTapped: Observable<Void> = Observable.empty()
    
    private let packages: [String:PackageAction]!
    private var requiresReboot: Bool = false
    
    init(with packages:[String: PackageAction]) {
        self.packages = packages
        super.init()
        
        self.packages.values.forEach({ action in
            switch action {
            case let .install(package):
                switch(package.installer) {
                case .macOsInstaller(let installer):
                    if (installer.requiresReboot) {
                        self.requiresReboot = true
                    }
                default:
                    break
                }
            case let .uninstall(package):
                switch(package.installer) {
                case .macOsInstaller(let installer):
                    if (installer.requiresUninstallReboot) {
                        self.requiresReboot = true
                    }
                default:
                    break
                }
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(errors: [ProcessResult]) {
    
    }
    
    func requiresReboot(is requiresReboot: Bool) {
        
    }
    
    func showMain() {
        AppContext.windows.set(MainViewController(), for: MainWindowController.self)
    }
    
    func rebootSystem() {
        let source = "tell application \"Finder\"\nshut down\nend tell"
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        window.titleVisibility = .visible
        window.toolbar!.isVisible = false
        
        title = Strings.processCompletedTitle
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if (self.requiresReboot) {
            contentView.leftButton.title = Strings.restartLater
            contentView.rightButton.title = Strings.restartNow
            contentView.leftButton.sizeToFit()
            contentView.rightButton.sizeToFit()
            contentView.leftButton.isHidden = false
            
            contentView.leftButton.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.showMain()
            }).disposed(by: bag)
            
            contentView.rightButton.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.rebootSystem()
            }).disposed(by: bag)
            
        } else {
            contentView.rightButton.title = Strings.finish
            contentView.rightButton.sizeToFit()
            contentView.leftButton.isHidden = true
            
            contentView.rightButton.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.showMain()
            }).disposed(by: bag)
        }
        
    }
    
    
}

extension Package.Installer {
    func isCompatible() -> Bool {
        switch self {
        case .macOsInstaller(_):
            return true
        default:
            return false
        }
    }
}
