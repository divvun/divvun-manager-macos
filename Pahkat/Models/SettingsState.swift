//
//  SettingsState.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

class SettingsState {
    private let client: PahkatClient
    
    init(client: PahkatClient) {
        self.client = client
    }
    
    internal(set) lazy var repositories: [RepoConfig] = {
        return self.client.config.repos()
    }()
    
    internal(set) lazy var updateCheckInterval: UpdateFrequency = {
        if let v = self.client.config.get(uiSetting: SettingsKey.updateCheckInterval.rawValue) {
            return UpdateFrequency(rawValue: v) ?? .daily
        }
        return .daily
    }()
    
    internal(set) lazy var nextUpdateCheck: Date = {
        if let rawDate = self.client.config.get(uiSetting: SettingsKey.nextUpdateCheck.rawValue),
            let date = rawDate.iso8601 {
            return date
        }
        return Date.distantPast
    }()
    
    internal(set) lazy var interfaceLanguage: String = {
        return self.client.config.get(uiSetting: SettingsKey.interfaceLanguage.rawValue) ?? "en"
    }()
}
