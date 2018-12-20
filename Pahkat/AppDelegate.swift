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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    
    private let bag = DisposeBag()
    internal var requiresAppDeath = false
    
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
    
    func checkForSelfUpdate() -> PahkatClient? {
        guard let selfUpdatePath = Bundle.main.url(forResource: "selfupdate", withExtension: "json")?.path else {
            print("No selfupdate.json found in bundle.")
            return nil
        }
        
        guard let client = PahkatClient(configPath: selfUpdatePath, saveChanges: false) else {
            print("No PahkatClient generated for given config.")
            return nil
        }
        
        client.config.set(cachePath: "/tmp/pahkat-\(NSUserName())-\(Date().timeIntervalSince1970)")
        
        guard let repo = client.repos().first else {
            print("No repo found in config.")
            return nil
        }
        
        guard let package = repo.packages["divvun-installer-macos"], let status = repo.status(forPackage: package)?.status else {
            print("No self update package found!")
            return nil
        }
        
        print("Found divvun-installer-macos version: \(package.version) \(status)")
        
        switch status {
        case .notInstalled:
            print("Selfupdate: self not installed, likely debugging.")
        case .versionSkipped:
            print("Selfupdate: self is blocked from updating itself")
        case .requiresUpdate:
            return client
        default:
            break
        }
        
        return nil
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return requiresAppDeath
    }
    
    func launchMain() {
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
        
        // Make sure app always has a repo
        AppContext.settings.state.map { $0.repositories }
            .distinctUntilChanged()
            .filter { $0.isEmpty }
            .subscribe(onNext: { _ in
                let repos = [RepoConfig(url: URL(string: "https://pahkat.uit.no/repo/macos/")!, channel: .stable)]
                AppContext.settings.dispatch(event: SettingsEvent.setRepositoryConfigs(repos))
                AppContext.client.config.set(repos: repos)
                AppContext.client.refreshRepos()
                AppContext.store.dispatch(event: AppEvent.setRepositories(AppContext.client.repos()))
            }).disposed(by: bag)
        
        // If triggered by agent, only show update window.
        if ProcessInfo.processInfo.arguments.contains("update") {
            requiresAppDeath = true
            onUpdateRequested()
        } else {
            AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
        }
        
        #if DEBUG
        AppContext.settings.state.subscribe(onNext: {
            print($0)
        }).disposed(by: bag)
        
        AppContext.store.state.subscribe(onNext: {
            print($0)
        }).disposed(by: bag)
        #endif
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure Sentry.io
        do {
            Client.shared = try Client(dsn: "https://554b508acddd44e98c5b3dc70f8641c1@sentry.io/1357390")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("\(error)")
            // Wrong DSN or KSCrash not installed
        }
        
        NSApp.mainMenu = MainMenu.loadFromNib()
        AppDelegate.instance = self
        
        if !ProcessInfo.processInfo.arguments.contains("first-run"), let client = checkForSelfUpdate() {
            AppContext.windows.show(SelfUpdateWindowController.self,
                                    viewController: SelfUpdateViewController(client: client),
                                    sender: self)
            // Early return
            return
        }
        
        launchMain()
    }
}

