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
    var onRestartButtonTapped: Observable<Void> = Observable.empty()
    var onFinishButtonTapped: Observable<Void> = Observable.empty()
    
    private let packages: [URL: PackageAction]
    private let requiresReboot: Bool
    
    init(with packages: [URL: PackageAction]) {
        self.packages = packages
        var requiresReboot = false
        
        for action in packages.values {
            guard case let .macOsInstaller(installer) = action.package.installer else {
                continue
            }
            
            if case .install(_) = action, installer.requiresReboot {
                requiresReboot = true
                break
            } else if case .uninstall(_) = action, installer.requiresUninstallReboot {
                requiresReboot = true
                break
            }
        }
        
        self.requiresReboot = requiresReboot
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(errors: [Error]) {
        fatalError("unimplemented")
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
