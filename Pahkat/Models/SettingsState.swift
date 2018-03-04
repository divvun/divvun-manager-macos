//
//  SettingsState.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct SettingsState: Codable {
    //
    internal(set) var repositories: [RepoConfig] = [RepoConfig.init(url: URL(string: "https://x.brendan.so/macos-repo/")!, channel: .stable)]
    //UserDefaults.standard["repositories"] ?? []
    internal(set) var updateCheckInterval: UpdateFrequency = UserDefaults.standard[SettingsKey.updateCheckInterval] ?? .daily
    internal(set) var nextUpdateCheck: Date = UserDefaults.standard[SettingsKey.nextUpdateCheck] ?? .distantPast
    internal(set) var interfaceLanguage: String = UserDefaults.standard.getArray(SettingsKey.interfaceLanguage.rawValue)?[0]
        ?? Locale.current.languageCode ?? "en"
}
