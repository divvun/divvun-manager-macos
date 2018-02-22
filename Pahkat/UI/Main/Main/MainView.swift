//
//  MainView.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class MainView: View {
    @IBOutlet weak var primaryLabel: NSTextField!
    @IBOutlet weak var primaryButton: NSButton!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func awakeFromNib() {
        primaryButton.title = Strings.noPackagesSelected
        primaryLabel.stringValue = Strings.appName
    }
}


