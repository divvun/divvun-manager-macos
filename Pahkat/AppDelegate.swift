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
import STPrivilegedTask

class AppContext {
    static let rpc = PahkatRPCService()
    static let settings = SettingsStore()
    static let store = AppStore()
    static let windows = WindowManager()
    
    private init() { fatalError() }
}

enum PrivilegedTaskLaunchResult {
    case launched
    case cancelled
    case failure(NSError)
}

extension STPrivilegedTask {
    func launchSafe() -> PrivilegedTaskLaunchResult {
        let status = self.launch()
        switch status {
        case 0:
            return .launched
        case -60006:
            return .cancelled
        default:
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            return .failure(error)
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    
    let bag = DisposeBag()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
        NSApp.mainMenu = NSMenu.loadFromNib(path: "MainMenu")
        
        // TODO: Check if run at startup and don't show window.
        AppContext.windows.show(MainWindowController.self)
        
        try! AppContext.rpc.settings()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: {
                AppContext.settings.set(state: $0)
            }, onError: {
                NSAlert(error: $0).runModal()
            })
            .disposed(by: bag)

        // If the repository URL settings are changed, download new repo and push into AppStore.
        AppContext.settings.state.map { $0.repositoryURL }
            .distinctUntilChanged()
            .flatMapLatest { try AppContext.rpc.repository(with: $0).asObservable() }
            .subscribe(onNext: { AppContext.store.dispatch(event: AppEvent.setRepository($0)) })
            .disposed(by: bag)
        
//        let socket = try Socket(.unix, type: .stream, protocol: Socket.Protocol)
        
        _ = AppContext.rpc
        
//        AppContext.windows.show(UpdateWindowController.self)
        
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        NSApp.mainMenu = NSMenu()
        NSApp.mainMenu = NSMenu.loadFromNib(path: "MainMenu")
        
        UserDefaults.standard.set(["nn"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
//        let task = STPrivilegedTask(launchPath: "/usr/bin/nc", arguments: ["localhost", "3030"])!
//
//        switch task.launchSafe() {
//        case .launched:
//            task.outputFileHandle.readabilityHandler = { handle in
//                guard let string = String(data: handle.availableData, encoding: .utf8) else {
//                    print("bad dartar")
//                    return
//                }
//                print("OUT: \(string)")
//            }
//        case .cancelled:
//            print("User cancelled.")
//        case let .failure(error):
//            print(error)
//        }
        
        // HOLY SHIT IT WORKS
//        task.outputFileHandle.write("{}\n".data(using: .utf8)!)
        
//        AppContext.store.state.subscribe(onNext: {
//            print($0)
//        }).disposed(by: bag)
        
//        print(ISO639.get(tag: "kpv"))
        
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
    private lazy var appDelegate = AppDelegate()
    
    override init() {
        super.init()
        
        UserDefaults.standard.set(["nn"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
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
