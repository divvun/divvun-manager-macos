////
////  main.swift
////  agenthelper
////
////  Created by Brendan Molloy on 2018-03-04.
////  Copyright © 2018 Divvun. All rights reserved.
////
//
import Foundation
import Cocoa
import RxSwift

//let preferences = UserDefaults.standard
//
////func requestRepos(_ configs: [RepoConfig], rpc: PahkatRPCService) throws -> Observable<[RepositoryIndex]> {
////    return Observable.from(try configs.map { config in try rpc.repository(with: config).asObservable() })
////        .merge()
////        .toArray()
////        .flatMapLatest { (repos: [RepositoryIndex]) -> Observable<[RepositoryIndex]> in
////            return Observable.from(try repos.map { repo in try rpc.statuses(for: repo.meta.base).asObservable().map { (repo, $0) } })
////                .merge()
////                .map {
////                    print($0.1)
////                    $0.0.set(statuses: $0.1)
////                    return $0.0
////                }
////                .toArray()
////        }
////}
//
//func pahkatEvent(eventID: PahkatAppleEvent) -> NSAppleEventDescriptor {
//    return NSAppleEventDescriptor.appleEvent(withEventClass: PahkatAppleEvent.classID,
//                                             eventID: eventID.rawValue,
//                                             targetDescriptor: nil,
//                                             returnID: Int16(kAutoGenerateReturnID),
//                                             transactionID: Int32(kAnyTransactionID))
//}
//
//func launchConfig(eventID: PahkatAppleEvent) -> [NSWorkspace.LaunchConfigurationKey: Any] {
//    return [
//        NSWorkspace.LaunchConfigurationKey.appleEvent: pahkatEvent(eventID: eventID),
//        NSWorkspace.LaunchConfigurationKey.arguments: [eventID.stringValue]
//    ]
//}
//
//func openAppWith(event: PahkatAppleEvent) {
//    try! NSWorkspace.shared.launchApplication(at: Bundle.main.bundleURL, options: .default, configuration: launchConfig(eventID: event))
//}
//
//func checkForUpdates() {
////    guard let configs = preferences.get(json: SettingsKey.repositories, type: [RepoConfig].self) else {
////        return
////    }
////    guard let rpc = PahkatRPCService() else { return }
////
////    let _ = try! requestRepos(configs, rpc: rpc)
////        .subscribeOn(CurrentThreadScheduler.instance)
////        .observeOn(CurrentThreadScheduler.instance)
////        .subscribe(onNext: { repos in
////            for repo in repos {
////                if let _ = repo.statuses.first(where: { $0.1.status == .requiresUpdate }) {
////                    print("Updates found!")
////                    openAppWith(event: .update)
////                    exit(0)
////                }
////            }
////            print("No updates found.")
////            exit(0)
////        }, onError: {
////            print($0)
////            exit(1)
////        })
//}
//
//func restartApp() {
//    let exe = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/Pahkat")
//
//    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.executableURL == exe }) {
//        app.forceTerminate()
//    }
//
//    openAppWith(event: .restartApp)
//    exit(0)
//}
//
//print(Bundle.main)
//print(CommandLine.arguments)
//
//if CommandLine.argc > 1 {
//    switch CommandLine.arguments[1] {
//    case "restart-app":
//        restartApp()
//    default:
//        checkForUpdates()
//    }
//} else {
//    checkForUpdates()
//}
//
while true {
    usleep(50000)
}
