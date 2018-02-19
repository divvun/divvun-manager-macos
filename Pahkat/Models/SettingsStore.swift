//
//  SettingsStore.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum PeriodInterval: String {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case fortnightly = "Fortnightly"
    case monthly = "Monthly"
}

struct SettingsState {
    fileprivate(set) var repositoryURL: URL = URL(string: "https://x.brendan.so/macos-repo/")!
        //UserDefaults.standard.url(forKey: "repositoryURL") ?? URL(string: "http://localhost:8000")!
    fileprivate(set) var updateCheckInterval: PeriodInterval =
        PeriodInterval(rawValue: UserDefaults.standard.string(forKey: "updateCheckInterval") ?? "") ?? .daily
    fileprivate(set) var nextUpdateCheck: Date =
        UserDefaults.standard.object(forKey: "nextUpdateCheck") as? Date ?? .distantPast
    fileprivate(set) var interfaceLanguage: String =
        UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "en"
}

enum SettingsEvent {
    case setRepositoryURL(URL)
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
        case let .setRepositoryURL(url):
            newState.repositoryURL = url
            prefs.set(url, forKey: "repositoryURL")
        case let .setUpdateCheckInterval(period):
            newState.updateCheckInterval = period
            prefs.set(period, forKey: "updateCheckInterval")
        }
        
        return newState
    }
    
    init() {
        super.init(initialState: SettingsState(), reducers: [self.reducer])
    }
}
