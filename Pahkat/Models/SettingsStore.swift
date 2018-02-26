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

struct SettingsState: Codable {
    // TODO: stub URL and handle rationally
    fileprivate(set) var repositoryURL: URL = URL(string: "https://x.brendan.so/macos-repo/")!
    fileprivate(set) var updateCheckInterval: PeriodInterval = .daily
    fileprivate(set) var nextUpdateCheck: Date = .distantPast
    fileprivate(set) var interfaceLanguage: String = "en"
}

//enum SettingsEvent {
//    case setRepositoryURL(URL)
//    case setUpdateCheckInterval(PeriodInterval)
//    case setNextUpdateCheck(Date)
//    case setInterfaceLanguage(String)
//}

class SettingsStore { //: RxStore<SettingsState, SettingsEvent> {
//    let prefs = UserDefaults.standard
//
//    func reducer(state: SettingsState, event: SettingsEvent) -> SettingsState {
//        var newState = state
//
//        switch (event) {
//        case let .setInterfaceLanguage(language):
//            newState.interfaceLanguage = language
//            prefs.set(language, forKey: "language")
//        case let .setNextUpdateCheck(date):
//            newState.nextUpdateCheck = date
//            prefs.set(date, forKey: "nextUpdateCheck")
//        case let .setRepositoryURL(url):
//            newState.repositoryURL = url
//            prefs.set(url, forKey: "repositoryURL")
//        case let .setUpdateCheckInterval(period):
//            newState.updateCheckInterval = period
//            prefs.set(period, forKey: "updateCheckInterval")
//        }
//
//        return newState
//    }
//
//    init() {
//        super.init(initialState: SettingsState(), reducers: [self.reducer])
//    }
    
    private let subject = BehaviorSubject<SettingsState>(value: SettingsState())
    var state: Observable<SettingsState> {
        return subject.asObservable()
    }
    
    func set(state: SettingsState) {
        subject.onNext(state)
    }
}
