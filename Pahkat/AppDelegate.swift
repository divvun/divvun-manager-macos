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
    static let rpc = PahkatRPCService()!
    static let settings = SettingsStore()
    static let store = AppStore()
    static let windows = WindowManager()
    
    private init() { fatalError() }
}

class MainMenu: NSMenu {
    @IBOutlet weak var prefsMenuItem: NSMenuItem!
    
    @objc func onClickMainMenuPreferences(_ sender: NSObject) {
        AppContext.windows.show(SettingsWindowController.self)
    }
    
    override func awakeFromNib() {
        prefsMenuItem.target = self
        prefsMenuItem.action = #selector(MainMenu.onClickMainMenuPreferences(_:))
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static weak var instance: AppDelegate!
    
    let bag = DisposeBag()
    
    func requestRepos(_ configs: [RepoConfig]) throws -> Observable<[RepositoryIndex]> {
        return Observable.from(try configs.map { config in try AppContext.rpc.repository(with: config).asObservable() })
            .merge()
            .toArray()
            .flatMapLatest { (repos: [RepositoryIndex]) -> Observable<[RepositoryIndex]> in
                return Observable.from(try repos.map { repo in try AppContext.rpc.statuses(for: repo.meta.base).asObservable().map { (repo, $0) } })
                    .merge()
                    .map {
                        print($0.1)
                        $0.0.set(statuses: $0.1)
                        return $0.0
                    }
                    .toArray()
            }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
        NSApp.mainMenu = MainMenu.loadFromNib()
        
        // TODO: Check if run at startup and don't show window.
        AppContext.windows.show(MainWindowController.self)
        
        AppContext.settings.state.subscribe(onNext: {
            print($0)
        }).disposed(by: bag)
        
        AppContext.store.state.subscribe(onNext: {
            print($0)
        }).disposed(by: bag)
    }
}

class App: NSApplication {
    private lazy var appDelegate = AppDelegate()
    
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
