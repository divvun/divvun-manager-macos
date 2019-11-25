//
//  SettingsState.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import PahkatClient

class SettingsState {
    private let client: MacOSPackageStore
    
    init(client: MacOSPackageStore) {
        self.client = client
    }
    
    lazy var repositories: [RepoRecord] = {
        return try! self.client.config().repos()
    }()
    
    lazy var updateCheckInterval: UpdateFrequency = {
        if let v = try! self.client.config().get(uiSetting: SettingsKey.updateCheckInterval.rawValue) {
            return UpdateFrequency(rawValue: v) ?? .daily
        }
        return .daily
    }()
    
    lazy var nextUpdateCheck: Date = {
        if let rawDate = try! self.client.config().get(uiSetting: SettingsKey.nextUpdateCheck.rawValue),
            let date = rawDate.iso8601 {
            return date
        }
        return Date.distantPast
    }()
    
    lazy var interfaceLanguage: String = {
        return (try? self.client.config().get(uiSetting: SettingsKey.interfaceLanguage.rawValue)) ?? "en"
    }()
}
