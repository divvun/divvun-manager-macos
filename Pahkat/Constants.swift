//
//  Constants.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum PahkatAppleEvent: UInt32 {
    static let classID: UInt32 = 0x504B4854 // "PHKT"
    case update = 0x504B5430 // "PKT0"
}
