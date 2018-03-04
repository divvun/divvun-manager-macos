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
            prefs[SettingsKey.interfaceLanguage] = [language]
            newState.interfaceLanguage = language
        case let .setNextUpdateCheck(date):
            prefs[SettingsKey.nextUpdateCheck] = date
            newState.nextUpdateCheck = date
        case let .setUpdateCheckInterval(period):
            prefs[SettingsKey.updateCheckInterval] = period
            newState.updateCheckInterval = period
        case let .setRepositoryConfigs(configs):
            prefs[SettingsKey.repositories] = configs
            newState.repositories = configs
        }

        return newState
    }

    init() {
        super.init(initialState: SettingsState(), reducers: [self.reducer])
    }
}
