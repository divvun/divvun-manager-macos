//
//  SettingsState.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct SettingsState: Codable {
    internal(set) var repositories: [RepoConfig] = UserDefaults.standard[SettingsKey.repositories] ?? []
    internal(set) var updateCheckInterval: UpdateFrequency = {
        if let v = UserDefaults.standard.string(forKey: SettingsKey.updateCheckInterval.rawValue) {
            return UpdateFrequency(rawValue: v) ?? .daily
        }
        return .daily
    }()
    internal(set) var nextUpdateCheck: Date = UserDefaults.standard[SettingsKey.nextUpdateCheck] ?? .distantPast
    internal(set) var interfaceLanguage: String = {
        guard let v = UserDefaults.standard.object(forKey: SettingsKey.interfaceLanguage.rawValue) as? [String] else {
            return Locale.current.languageCode ?? "en"
        }
        return v[0]
    }()
}
