//
//  SettingsStore.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

// TODO: deduplicate
enum PeriodInterval: String, Codable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case fortnightly = "Fortnightly"
    case monthly = "Monthly"
}

struct RepoConfig: Codable, Equatable {
    let url: URL
    let channel: String
    
    static func ==(lhs: RepoConfig, rhs: RepoConfig) -> Bool {
        return lhs.url == rhs.url && lhs.channel == rhs.channel
    }
}

struct SettingsState: Codable {
    fileprivate(set) var repositories: [RepoConfig] = [RepoConfig.init(url: URL(string: "https://x.brendan.so/macos-repo/")!, channel: "test")]
    fileprivate(set) var updateCheckInterval: PeriodInterval = .daily
    fileprivate(set) var nextUpdateCheck: Date = .distantPast
    fileprivate(set) var interfaceLanguage: String = Locale.current.languageCode ?? "en"
}

enum SettingsEvent {
    case setRepositoryConfigs([RepoConfig])
    case setUpdateCheckInterval(PeriodInterval)
    case setNextUpdateCheck(Date)
    case setInterfaceLanguage(String)
}

class SettingsStore: RxStore<SettingsState, SettingsEvent> {
    let prefs = UserDefaults.standard

    func reducer(state: SettingsState, event: SettingsEvent) -> SettingsState {
        var newState = state

        switch (event) {
        case let .setInterfaceLanguage(language):
            newState.interfaceLanguage = language
            prefs.set(language, forKey: "language")
        case let .setNextUpdateCheck(date):
            newState.nextUpdateCheck = date
            prefs.set(date, forKey: "nextUpdateCheck")
        case let .setUpdateCheckInterval(period):
            newState.updateCheckInterval = period
            prefs.set(period, forKey: "updateCheckInterval")
        case let .setRepositoryConfigs(configs):
            // This one is saved by the IPC
            newState.repositories = configs
        }

        return newState
    }

    init() {
        super.init(initialState: SettingsState(), reducers: [self.reducer])
    }
}
