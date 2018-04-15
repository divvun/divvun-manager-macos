//
//  AppDelegate.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import Sentry
import Sparkle

class AppContext {
    static let rpc = PahkatRPCService()!
    static let settings = SettingsStore()
    static let store = AppStore()
    static let windows = WindowManager()
    
    private init() { fatalError() }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    
    private let bag = DisposeBag()
    internal var requiresAppDeath = false
    
    func requestRepos(_ configs: [RepoConfig]) throws -> Observable<[RepositoryIndex]> {
        return Observable.from(try configs.map { config in try AppContext.rpc.repository(with: config).asObservable().take(1) })
            .merge()
            .toArray()
            .flatMapLatest { (repos: [RepositoryIndex]) -> Observable<[RepositoryIndex]> in
                return Observable.from(try repos.map { repo in try AppContext.rpc.statuses(for: repo.meta.base).asObservable().take(1).map { (repo, $0) } })
                    .merge()
                    .map {
                        print($0.1)
                        $0.0.set(statuses: $0.1)
                        return $0.0
                    }
                    .toArray()
            }.take(1)
    }
    
    private func onUpdateRequested() {
        AppContext.windows.show(UpdateWindowController.self, viewController: UpdateViewController())
    }
    
    @objc func handleUpdateEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventManager) {
        onUpdateRequested()
    }
    
    @objc func handleReopenEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventManager) {
        if let window = NSApp.windows.filter({ $0.isVisible }).first {
            window.windowController?.showWindow(self)
        } else {
            AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return requiresAppDeath
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure Sentry.io
        do {
            Client.shared = try Client(dsn: "https://85710416203c49ec87d9317948dad3c5:cab1830577f046d9a02ad04e9a5f8488@sentry.io/292199")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("\(error)")
            // Wrong DSN or KSCrash not installed
        }
        
        AppContext.rpc.pahkatcIPC.onComplete = { exitCode in
            if exitCode != 0 && exitCode != 15 {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "The RPC client has crashed. Please restart the app and try again."
                    alert.runModal()
                    exit(101)
                }
            }
        }
        
        NSApp.mainMenu = MainMenu.loadFromNib()
        AppDelegate.instance = self
        
        // Handle external requests from agent helper
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleUpdateEvent(_:withReplyEvent:)),
            forEventClass: PahkatAppleEvent.classID,
            andEventID: PahkatAppleEvent.update.rawValue)
        
        // Handle event for reopen window because AppDelegate one is never called…
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleReopenEvent(_:withReplyEvent:)),
            forEventClass: kCoreEventClass,
            andEventID: kAEReopenApplication)
        
        // If triggered by agent, only show update window.
        if ProcessInfo.processInfo.arguments.contains("update") {
            requiresAppDeath = true
            onUpdateRequested()
        } else {
            AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
        }
        
        // Manage the launch agents
        AppContext.settings.state.map { $0.updateCheckInterval }
            .distinctUntilChanged()
            .subscribe(onNext: { interval in
                switch interval {
                case .never:
                    try? LaunchdService.removeLaunchAgent()
                default:
                    _ = try? LaunchdService.saveNewLaunchAgent(startInterval: interval.asSeconds)
                }
            }).disposed(by: bag)
        
#if DEBUG
        AppContext.settings.state.subscribe(onNext: {
            print($0)
        }).disposed(by: bag)
        
        AppContext.store.state.subscribe(onNext: {
            print($0)
        }).disposed(by: bag)
#endif
    }
}

