//
//  SelfUpdateViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-12-11.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import PahkatClient

protocol SelfUpdateViewable: class {
    
}

class SelfUpdateViewController: ViewController<SelfUpdateView>, SelfUpdateViewable, NSWindowDelegate {
    private let client: MacOSPackageStore
    private let package: Package
    private let key: PackageKey
    private let status: PackageStatusResponse
    
    private let bag = DisposeBag()
    
    init(client: SelfUpdateClient) {
        self.client = client.client
        self.package = client.package
        self.key = try! self.client.repoIndexesWithStatuses()[0].absoluteKey(for: package)
        self.status = client.status
        
        super.init()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.contentView.progress.startAnimation(self)
        self.download()
    }
    
    func showMoreInfo(error: Error) {
        let alert = NSAlert()
        alert.messageText = Strings.downloadError
        alert.informativeText = String(describing: error)
        
        alert.runModal()
    }
    
    func handle(error: Error) {
        log.severe(error)
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = error.localizedDescription
            
            alert.alertStyle = .critical
            alert.addButton(withTitle: Strings.ok)
            alert.addButton(withTitle: "More Info")
            switch alert.runModal() {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                break
            case NSApplication.ModalResponse.alertSecondButtonReturn:
                self.showMoreInfo(error: error)
            default:
                break
            }
            
            AppDelegate.instance.launchMain()
            AppContext.windows.close(SelfUpdateWindowController.self)
        }
    }
    
    private let byteCountFormatter = ByteCountFormatter()
    
    private func download() {
        try! AppContext.client.config()
            .set(uiSetting: "no.divvun.Pahkat.updatingTo", value: package.version)
        
        client.download(packageKey: key, delegate: self)
    }
    
    private func install(with action: TransactionAction<InstallerTarget>) {
        
    }
    
    private func install() {
        let action = TransactionAction.install(self.key, target: self.status.target)
        self.contentView.subtitle.stringValue = Strings.installingPackage(name: Strings.appName, version: self.package.nativeVersion)
        
        if action.target == .system {
            PahkatAdminReceiver.checkForAdminService().subscribe(onCompleted: {
                try! self.client.transaction(actions: [action]).process(delegate: self)
            }, onError: { error in
                self.handle(error: error)
            }).disposed(by: self.bag)
        }
    }
    
    private func reloadApp() {
        let p = Process()
        p.launchPath = "/usr/bin/nohup"
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice
        p.arguments = ["sh", "-c", "killall -9 'Divvun Installer'; open /Applications/Divvun\\ Installer.app --args first-run"]
        p.launch()
        p.waitUntilExit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SelfUpdateViewController: PackageDownloadDelegate {
    var isDownloadCancelled: Bool {
        return false
    }
    
    func downloadDidProgress(_ packageKey: PackageKey, current: UInt64, maximum: UInt64) {
        self.contentView.progress.isIndeterminate = false
        self.contentView.progress.minValue = 0.0
        self.contentView.progress.maxValue = Double(current)
        self.contentView.progress.doubleValue = Double(maximum)

        let downloadStr = byteCountFormatter.string(fromByteCount: Int64(current))
        let totalStr = byteCountFormatter.string(fromByteCount: Int64(maximum))

        self.contentView.subtitle.stringValue = "\(Strings.downloading) \(downloadStr) / \(totalStr)"
    }
    
    func downloadDidComplete(_ packageKey: PackageKey, path: String) {
        DispatchQueue.main.async {
            self.install()
        }
    }
    
    func downloadDidCancel(_ packageKey: PackageKey) {
        // TODO: should be unreachable
        self.handle(error: XPCError(message: "Cancelled"))
    }
    
    func downloadDidError(_ packageKey: PackageKey, error: Error) {
        self.contentView.subtitle.stringValue = Strings.downloadError
        self.handle(error: error)
    }
}

extension SelfUpdateViewController: PackageTransactionDelegate {
    func transactionDidComplete(_ id: UInt32) {
        DispatchQueue.main.async {
            self.contentView.subtitle.stringValue = Strings.waitingForCompletion
            self.reloadApp()
        }
    }
    
    func transactionDidCancel(_ id: UInt32) {
        self.contentView.subtitle.stringValue = Strings.downloadError
        self.handle(error: XPCError(message: "There was an error installing this update."))
    }
    
    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
        self.contentView.subtitle.stringValue = Strings.downloadError
        self.handle(error: XPCError(message: "There was an error installing this update."))
    }
    
    func isTransactionCancelled(_ id: UInt32) -> Bool {
        return false
    }
    
    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey) {
    }
    
    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey) {
    }
    
    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32) {
    }
}
