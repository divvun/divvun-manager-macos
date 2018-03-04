//
//  SettingsStore.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct RepoConfig: Codable, Equatable {
    let url: URL
    let channel: Repository.Channels
    
    static func ==(lhs: RepoConfig, rhs: RepoConfig) -> Bool {
        return lhs.url == rhs.url && lhs.channel == rhs.channel
    }
}

extension UserDefaults {
    func get<T>(_ key: String) -> T? {
        return self.object(forKey: key) as? T
    }
    
    func getArray<T>(_ key: String) -> [T]? {
        return self.array(forKey: key) as? [T]
    }
    
    subscript<T>(_ key: String) -> T? {
        get {
            return self.get(key)
        }
        set(value) {
            self.set(value, forKey: key)
        }
    }
    
    subscript<T: Codable>(json key: String) -> T? {
        get {
            if let data = self.data(forKey: key) {
                return try? JSONDecoder().decode(T.self, from: data)
            }
            return nil
        }
        set(value) {
            if let value = value {
                self.set(try? JSONEncoder().encode(value), forKey: key)
            } else {
                self.set(nil, forKey: key)
            }
        }
    }
}

struct SettingsState: Codable {
    //
    fileprivate(set) var repositories: [RepoConfig] = [RepoConfig.init(url: URL(string: "https://x.brendan.so/macos-repo/")!, channel: .stable)]
        //UserDefaults.standard["repositories"] ?? []
    fileprivate(set) var updateCheckInterval: UpdateFrequency = UserDefaults.standard["updateCheckInterval"] ?? .daily
    fileprivate(set) var nextUpdateCheck: Date = UserDefaults.standard["nextUpdateCheck"] ?? .distantPast
    fileprivate(set) var interfaceLanguage: String = UserDefaults.standard.getArray("AppleLanguages")?[0] ?? Locale.current.languageCode ?? "en"
}

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
            prefs[json: "repositories"] = newState.repositories
        case let .setInterfaceLanguage(language):
            prefs["AppleLanguages"] = [language]
            newState.interfaceLanguage = language
        case let .setNextUpdateCheck(date):
            prefs["nextUpdateCheck"] = date
            newState.nextUpdateCheck = date
        case let .setUpdateCheckInterval(period):
            prefs["updateCheckInterval"] = period
            newState.updateCheckInterval = period
        case let .setRepositoryConfigs(configs):
            prefs[json: "repositories"] = configs
            newState.repositories = configs
        }

        return newState
    }

    init() {
        super.init(initialState: SettingsState(), reducers: [self.reducer])
    }
}
