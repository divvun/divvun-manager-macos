//
//  UpdateWindow.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class UpdateWindow: Window {}

class UpdateWindowController: WindowController<UpdateWindow> {
    override func windowDidLoad() {
        self.contentWindow.set(viewController: UpdateViewController())
    }
}

