//
//  SettingsStore.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

enum SettingsEvent {
    case setRepositoryConfigs([RepoConfig])
    case updateRepoConfig(URL, Repository.Channels)
    case setUpdateCheckInterval(UpdateFrequency)
    case setNextUpdateCheck(Date)
    case setInterfaceLanguage(String)
}

class SettingsStore: RxStore<SettingsState, SettingsEvent> {
    let prefs = UserDefaults.standard

    func reducer(state: SettingsState, event: SettingsEvent) -> SettingsState {
        var newState = state

        switch (event) {
        case let .updateRepoConfig(url, channel):
            let newConfig = RepoConfig(url: url, channel: channel)
            if let index = newState.repositories.index(where: { $0.url == url }) {
                newState.repositories[index] = newConfig
            } else {
                newState.repositories.append(newConfig)
            }
            prefs[json: SettingsKey.repositories.rawValue] = newState.repositories
        case let .setInterfaceLanguage(language):
            prefs.setValue([language], forKeyPath: SettingsKey.interfaceLanguage.rawValue)
//            prefs[SettingsKey.interfaceLanguage] = [language]
            newState.interfaceLanguage = language
        case let .setNextUpdateCheck(date):
            prefs[SettingsKey.nextUpdateCheck] = date
            newState.nextUpdateCheck = date
        case let .setUpdateCheckInterval(period):
//            prefs.set(json: SettingsKey.updateCheckInterval, value: period)
//            prefs[SettingsKey.updateCheckInterval] = period.rawValue
            prefs.set(period.rawValue, forKey: SettingsKey.updateCheckInterval.rawValue)
            newState.updateCheckInterval = period
            print(prefs.object(forKey: SettingsKey.updateCheckInterval.rawValue))
        case let .setRepositoryConfigs(configs):
            prefs[SettingsKey.repositories] = configs
            newState.repositories = configs
        }

        return newState
    }

    init() {
        let s = SettingsState()
        super.init(initialState: s, reducers: [self.reducer])
        print(s)
    }
}
