//
//  CompatNSMenuItem.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-01-30.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Cocoa

@objc protocol LocalizationCompat {
    @objc var stringKey: String { get set }
}

@objc class CompatNSMenu: NSMenu, LocalizationCompat {
    @objc dynamic var stringKey: String = ""
}

@objc class CompatNSMenuItem: NSMenuItem, LocalizationCompat {
    @objc dynamic var stringKey: String = ""
}

