//
//  MainMenu.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import Cocoa

class MainMenu: NSMenu {
    @IBOutlet weak var prefsMenuItem: NSMenuItem!
    
    @objc func onClickMainMenuPreferences(_ sender: NSObject) {
        AppContext.windows.show(SettingsWindowController.self)
    }
    
    override func awakeFromNib() {
        prefsMenuItem.target = self
        prefsMenuItem.action = #selector(MainMenu.onClickMainMenuPreferences(_:))
    }
}
