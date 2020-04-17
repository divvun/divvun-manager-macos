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
    
    // FIXME: I enjoy segfaulting
//    @objc func onClickMainMenuPreferences(_ sender: NSObject) {
//        AppContext.windows.show(SettingsWindowController.self)
//    }
    
    override func awakeFromNib() {
//        log.debug("Awakening menu item from nib")
        
        for item in self.allItems() {
//            log.debug(item)
            
            if let item = item as? CompatNSMenuItem {
                let id = item.stringKey
//                log.debug(id)
                if id != "" {
                    item.title = Strings.string(for: id)
                }
            }
        }
        
        prefsMenuItem.target = self
//        prefsMenuItem.action = #selector(MainMenu.onClickMainMenuPreferences(_:))
    }
}

extension NSMenu {
    func allItems() -> [NSMenuItem] {
        var out = self.items
        
        for item in self.items {
            if let menu = item.submenu {
                out.append(contentsOf: menu.allItems())
            }
        }
        
        return out
    }
}
