//
//  main.swift
//  agenthelper
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift

let preferences = UserDefaults.standard

func requestRepos(_ configs: [RepoConfig], rpc: PahkatRPCService) throws -> Observable<[RepositoryIndex]> {
    return Observable.from(try configs.map { config in try rpc.repository(with: config).asObservable() })
        .merge()
        .toArray()
        .flatMapLatest { (repos: [RepositoryIndex]) -> Observable<[RepositoryIndex]> in
            return Observable.from(try repos.map { repo in try rpc.statuses(for: repo.meta.base).asObservable().map { (repo, $0) } })
                .merge()
                .map {
                    print($0.1)
                    $0.0.set(statuses: $0.1)
                    return $0.0
                }
                .toArray()
        }
}

func openMainApp() {
    let event = NSAppleEventDescriptor.appleEvent(withEventClass: PahkatAppleEvent.classID,
                                                  eventID: PahkatAppleEvent.update.rawValue,
                                                  targetDescriptor: nil,
                                                  returnID: Int16(kAutoGenerateReturnID),
                                                  transactionID: Int32(kAnyTransactionID))
    
    try! NSWorkspace.shared.launchApplication(at: Bundle.main.bundleURL, options: .default, configuration: [
        NSWorkspace.LaunchConfigurationKey.appleEvent: event,
        NSWorkspace.LaunchConfigurationKey.arguments: ["update"]
    ])
}

func checkForUpdates() {
    guard let configs = preferences.get(json: SettingsKey.repositories, type: [RepoConfig].self) else {
        return
    }
    guard let rpc = PahkatRPCService() else { return }
    
    let _ = try! requestRepos(configs, rpc: rpc)
        .subscribeOn(CurrentThreadScheduler.instance)
        .observeOn(CurrentThreadScheduler.instance)
        .subscribe(onNext: { repos in
            for repo in repos {
                if let _ = repo.statuses.first(where: { $0.1.status == .requiresUpdate }) {
                    print("Updates found!")
                    openMainApp()
                    exit(0)
                }
            }
            print("No updates found.")
            exit(0)
        })
}

print(Bundle.main)
checkForUpdates()

while true {
    usleep(50000)
}
