//
//  SettingsState.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

extension Formatter {
    struct Date {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            return formatter
        }()
    }
}

extension Date {
    var iso8601: String {
        return Formatter.Date.iso8601.string(from: self)
    }
}

extension String {
    var iso8601: Date? {
        return Formatter.Date.iso8601.date(from: self)
    }
}

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
