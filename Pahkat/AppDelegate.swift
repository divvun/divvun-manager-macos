//
//  AppDelegate.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import JSONRPCKit

class AppContext {
    static let rpc = PahkatRPCService()
    static let settings = SettingsStore()
    static let store = AppStore()
    static let windows = WindowManager()
    
    private init() { fatalError() }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    
    let bag = DisposeBag()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
        NSApp.mainMenu = NSMenu.loadFromNib(path: "MainMenu")
        
        print(Strings.appName)
        
        // TODO: Check if run at startup and don't show window.
        AppContext.windows.show(MainWindowController.self)
        
        // If the repository URL settings are changed, download new repo and push into AppStore.
        AppContext.settings.state.map { $0.repositoryURL }
            .distinctUntilChanged()
            .flatMapLatest { try AppContext.rpc.repository(with: $0).asObservable() }
            .subscribe(onNext: { AppContext.store.dispatch(event: AppEvent.setRepository($0)) })
            .disposed(by: bag)
        
        print(ISO639.get(tag: "kpv"))
        
        // Wake RPC service
//        _ = AppContext.rpc
//        try! AppContext.rpc.repository(with: URL(string: "http://localhost:8000/")!)
//            .flatMap { (repo: RepositoryIndex) -> Single<(Package, PackageInstallStatus)> in
//                let package = repo.packages["sme-kbd"]!
//                let o = try! AppContext.rpc.status(of: package, target: .user)
//                return o.flatMap { Single.just((package, $0)) }
//            }
//            .asObservable()
//            .flatMapLatest { (package: Package, status: PackageInstallStatus) -> Observable<(Package, PackageDownloadStatus)> in
//                print(status)
//                // Good flatMap vs latest example here
//                let o = try! AppContext.rpc.download(package, target: .user)
//                return o.flatMap { (progress: PackageDownloadStatus) -> Observable<(Package, PackageDownloadStatus)> in
//                    print(progress)
//                    return Observable.just((package, progress))
//                }
//            }
//            .filter { tuple in
//                let progress: PackageDownloadStatus = tuple.1
//                
//                if case PackageDownloadStatus.completed = progress {
//                    return true
//                } else {
//                    return false
//                }
//            }
//            .map { $0.0 }
//            .flatMapLatest { (package: Package) -> Observable<Package> in
//                let o = try! AppContext.rpc.install(package, target: .user)
//                return o.flatMap { (progress: PackageInstallStatus) -> Single<Package> in
//                    print(progress)
//                    return Single.just(package)
//                }.asObservable()
//            }
//            .flatMapLatest { (package: Package) -> Observable<PackageInstallStatus> in
//                try! AppContext.rpc.uninstall(package, target: .user).asObservable()
//            }
//            .subscribe(onNext: { print($0) }, onError: { print($0) })
//            .disposed(by: bag)
    }
}

class App: NSApplication {
    private let appDelegate = AppDelegate()
    
    override init() {
        super.init()
        
        self.delegate = appDelegate
    }
    
    override func terminate(_ sender: Any?) {
        AppContext.rpc.pahkatcIPC.terminate()
        AppContext.rpc.pahkatcIPC.waitUntilExit()
        super.terminate(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
