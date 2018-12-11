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
            fatalError("No selfupdate.json found in bundle.")
        }
        
        guard let client = PahkatClient(configPath: selfUpdatePath) else {
            fatalError("No PahkatClient generated for given config.")
        }
        
        guard let repo = client.repos().first else {
            fatalError("No repo found in config.")
        }
        
        guard let package = repo.packages["pahkat-client-macos"], let status = repo.status(for: package)?.status else {
            fatalError("No self update package found!")
        }
        
        print("Found pahkat-client-macos version: \(package.version) \(status)")
        
        switch status {
        case .notInstalled:
            print("Selfupdate: self not installed, likely debugging.")
            return client
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure Sentry.io
        do {
            Client.shared = try Client(dsn: "https://85710416203c49ec87d9317948dad3c5@sentry.io/292199")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("\(error)")
            // Wrong DSN or KSCrash not installed
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
        
        if let client = checkForSelfUpdate() {
            AppContext.windows.show(SelfUpdateWindowController.self,
                                    viewController: SelfUpdateViewController(client: client),
                                    sender: self)
            // Early return
            return
        }
        
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

