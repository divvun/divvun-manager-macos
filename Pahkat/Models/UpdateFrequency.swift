//
//  UpdateFrequency.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum UpdateFrequency: String, Codable {
    case daily
    case weekly
    case fortnightly
    case monthly
    case never
    
    var description: String {
        switch self {
        case .daily:
            return Strings.daily
        case .weekly:
            return Strings.weekly
        case .fortnightly:
            return Strings.everyTwoWeeks
        case .monthly:
            return Strings.everyFourWeeks
        case .never:
            return Strings.never
        }
    }
    
    var asSeconds: Int {
        let day = 60 * 60 * 24
        switch self {
        case .daily:
            return day
        case .weekly:
            return day * 7
        case .fortnightly:
            return day * 14
        case .monthly:
            return day * 28
        case .never:
            return 0
        }
    }
}
