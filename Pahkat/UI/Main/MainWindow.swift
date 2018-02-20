//
//  MainWindow.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class MainWindow: Window {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleButton: NSButton!
}

class MainWindowController: WindowController<MainWindow> {
    
    override func windowDidLoad() {
        DispatchQueue.main.async {
            self.contentWindow.set(viewController: MainViewController())
        }
    }
}
