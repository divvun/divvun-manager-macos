//
//  SelfUpdateWindow.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-12-11.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class SelfUpdateWindow: Window {}

class SelfUpdateWindowController: WindowController<SelfUpdateWindow> {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.titlebarAppearsTransparent = true
        self.window?.titleVisibility = .hidden
        self.window?.styleMask = .borderless
    }
}
