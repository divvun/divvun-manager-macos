//
//  SettingsWindow.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class SettingsWindow: Window {}

class SettingsWindowController: WindowController<SettingsWindow> {
    override func windowDidLoad() {
        self.contentWindow.set(viewController: SettingsViewController())
    }
}
