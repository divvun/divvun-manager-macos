//
//  SelfUpdateViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-12-11.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift

protocol SelfUpdateViewable: class {
    
}

class SelfUpdateViewController: ViewController<SelfUpdateView>, SelfUpdateViewable, NSWindowDelegate {
    private let client: PahkatClient
    private let repo: RepositoryIndex
    private let package: Package
    private let key: AbsolutePackageKey
    private let status: PackageStatusResponse
    
    private let bag = DisposeBag()
    
    init(client: PahkatClient) {
        self.client = client
        self.repo = client.repos()[0]
        self.package = repo.packages["pahkat-client-macos"]!
        self.key = repo.absoluteKey(for: package)
        self.status = repo.status(for: self.key)!
        
        super.init()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.contentView.progress.startAnimation(self)
        self.download()
    }
    
    func handle(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = error.localizedDescription
            
            alert.alertStyle = .critical
            alert.runModal()
            
            fatalError("The self-updater has crashed.")
        }
    }
    
    private func download() {
        let byteCountFormatter = ByteCountFormatter()
        client.download(packageKey: key, target: status.target)
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { progress in
                switch progress.status {
                case let .progress(downloaded, total):
                    self.contentView.progress.isIndeterminate = false
                    self.contentView.progress.minValue = 0.0
                    self.contentView.progress.maxValue = Double(total)
                    self.contentView.progress.doubleValue = Double(downloaded)
                    
                    let downloadStr = byteCountFormatter.string(fromByteCount: Int64(downloaded))
                    let totalStr = byteCountFormatter.string(fromByteCount: Int64(total))
                    
                    self.contentView.subtitle.stringValue = "\(Strings.downloading) \(downloadStr) / \(totalStr)"
                case let .error(error):
                    self.contentView.subtitle.stringValue = Strings.downloadError
                    self.handle(error: error)
                case .starting:
                    self.contentView.subtitle.stringValue = Strings.starting
                default:
                    break
                }
            }, onError: { error in
                DispatchQueue.main.async {
                    self.contentView.subtitle.stringValue = Strings.downloadError
                    self.handle(error: error)
                }
            }, onCompleted: {
                DispatchQueue.main.async {
                    self.install()
                }
            }).disposed(by: bag)
    }
    
    private func install() {
        let action = TransactionAction.init(action: .install, id: self.key, target: self.status.target)
        self.contentView.subtitle.stringValue = Strings.installingPackage(name: Strings.appName, version: self.package.version)
        
        client.transaction(of: [action]).asObservable()
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .flatMapLatest { tx in tx.process() }
            .subscribe(onError: { error in
                DispatchQueue.main.async {
                    self.contentView.subtitle.stringValue = Strings.downloadError
                    self.handle(error: error)
                }
            }, onCompleted: {
                DispatchQueue.main.async {
                    self.contentView.subtitle.stringValue = Strings.waitingForCompletion
                    self.reloadApp()
                }
            }).disposed(by: bag)
    }
    
    private func reloadApp() {
        if LaunchdService.restartApp() {
            return
        }
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = "\(Strings.appName) has failed to reload itself. Please relaunch the app yourself."
            
            alert.alertStyle = .critical
            alert.runModal()
            
            fatalError("The self-updater failed to relaunch itself.")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
