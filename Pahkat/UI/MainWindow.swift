//
//  MainWindow.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class MainWindow: Window {}

class MainWindowController: WindowController<MainWindow> {
    override func windowDidLoad() {
        self.contentWindow.set(viewController: MainViewController())
    }
}
