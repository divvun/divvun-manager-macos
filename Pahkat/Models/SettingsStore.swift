//
//  SettingsStore.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import PahkatClient

enum SettingsEvent {
    case setRepositoryConfigs([RepoRecord])
    case setUpdateCheckInterval(UpdateFrequency)
    case setNextUpdateCheck(Date)
    case setInterfaceLanguage(String)
}

class SettingsStore: RxStore<SettingsState, SettingsEvent> {
    private let client: MacOSPackageStore
    
    init() {
        client = AppContext.client
        let s = SettingsState(client: client)
        super.init(initialState: s, reducers: [SettingsStore.reducer(client: client)])
        log.debug(s)
    }
    
    static func reducer(client: MacOSPackageStore) -> (SettingsState, SettingsEvent) -> SettingsState {
        return { (state: SettingsState, event: SettingsEvent) -> SettingsState in
            let newState = state

            switch (event) {
            case let .setInterfaceLanguage(language):
                if language == "" {
                    try! client.config().set(uiSetting: SettingsKey.interfaceLanguage.rawValue, value: nil)
                    UserDefaults.standard.set(nil, forKey: "AppleLanguages")
                } else {
                    try! client.config().set(uiSetting: SettingsKey.interfaceLanguage.rawValue, value: language)
                    UserDefaults.standard.set([language], forKey: "AppleLanguages")
                }
                newState.interfaceLanguage = language
            case let .setNextUpdateCheck(date):
                try! client.config().set(uiSetting: SettingsKey.nextUpdateCheck.rawValue, value: date.iso8601)
                newState.nextUpdateCheck = date
            case let .setUpdateCheckInterval(period):
                try! client.config().set(uiSetting: SettingsKey.updateCheckInterval.rawValue, value: period.rawValue)
                newState.updateCheckInterval = period
            case let .setRepositoryConfigs(configs):
                try! client.config().set(repos: configs)
                newState.repositories = configs
            }

            return newState
        }
    }
}
