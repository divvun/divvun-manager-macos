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
import XCGLogger

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    
    private let bag = DisposeBag()
    internal var requiresAppDeath = false
    
//    private func onUpdateRequested() {
//        AppContext.windows.show(UpdateWindowController.self, viewController: UpdateViewController())
//    }
    
    @objc func handleUpdateEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventManager) {
//        onUpdateRequested()
        todo()
    }
    
    @objc func handleReopenEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventManager) {
        if let window = NSApp.windows.filter({ $0.isVisible }).first {
            window.windowController?.showWindow(self)
        } else {
//            AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return requiresAppDeath
    }
    
    func launchMain() {
//        log.debug("Setting event handler for Apple events")
//
//        // Handle external requests from agent helper
////        NSAppleEventManager.shared().setEventHandler(
////            self,
////            andSelector: #selector(handleUpdateEvent(_:withReplyEvent:)),
////            forEventClass: PahkatAppleEvent.classID,
////            andEventID: PahkatAppleEvent.update.rawValue)
////        
//        log.debug("Setting event handler for core open event")
//        
//        // Handle event for reopen window because AppDelegate one is never called…
////        NSAppleEventManager.shared().setEventHandler(
////            self,
////            andSelector: #selector(handleReopenEvent(_:withReplyEvent:)),
////            forEventClass: kCoreEventClass,
////            andEventID: kAEReopenApplication)
//        
//        log.debug("Managing launch agents")
//        
//        // Manage the launch agents
////        AppContext.settings.state.map { $0.updateCheckInterval }
////            .distinctUntilChanged()
////            .subscribe(onNext: { interval in
////                switch interval {
////                case .never:
////                    try? LaunchdService.removeLaunchAgent()
////                default:
////                    _ = try? LaunchdService.saveNewLaunchAgent(startInterval: interval.asSeconds)
////                }
////            }).disposed(by: bag)
//        
//        log.debug("Ensure always has a repo")
//        
//        // Make sure app always has a repo
////        AppContext.settings.state.map { $0.repositories }
////            .distinctUntilChanged()
////            .filter { $0.isEmpty }
////            .subscribe(onNext: { _ in
////                let repos = [RepoRecord(url: URL(string: "https://pahkat.uit.no/repo/macos/")!, channel: .stable)]
////                AppContext.settings.dispatch(event: SettingsEvent.setRepositoryConfigs(repos))
////                do {
////                    try AppContext.client.config().set(repos: repos)
////                    try AppContext.client.refreshRepos()
////                    AppContext.store.dispatch(event: AppEvent.setRepositories(try AppContext.client.repoIndexesWithStatuses()))
////                } catch {
////                    fatalError(String(describing: error))
////                }
////            }).disposed(by: bag)
//        
//        // If triggered by agent, only show update window.
//        if ProcessInfo.processInfo.arguments.contains("update") {
//            log.debug("Update requested")
//            
//            requiresAppDeath = true
////            onUpdateRequested()
//        } else {
//            log.debug("Show main window controller")
            AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
//        }
//        
//        #if DEBUG
//        AppContext.settings.state.subscribe(onNext: {
//            log.debug($0)
//        }).disposed(by: bag)
//        
//        AppContext.store.state.subscribe(onNext: {
//            log.debug($0)
//        }).disposed(by: bag)
//        #endif
    }
    
    private func configureLogging() {
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "/tmp/divvun-installer.log", fileLevel: .debug)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureLogging()
        
        // Configure Sentry.io
        do {
            Client.shared = try Client(dsn: "https://554b508acddd44e98c5b3dc70f8641c1@sentry.io/1357390")
            try Client.shared?.startCrashHandler()
        } catch let error {
            log.severe(error)
            // Wrong DSN or KSCrash not installed
        }
        
        AppDelegate.instance = self
        
//        let client = SelfUpdateClient()
        
//        let _ = client?.assertSuccessfulUpdate()
        
//        if !ProcessInfo.processInfo.arguments.contains("first-run"), let client = client, client.checkForSelfUpdate() {
//            log.debug("Loading self update view controller")
//            AppContext.windows.show(SelfUpdateWindowController.self,
//                                    viewController: SelfUpdateViewController(client: client),
//                                    sender: self)
            // Early return
//            return
//        }
        
        launchMain()
    }
}
