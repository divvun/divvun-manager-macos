//
//  UpdateView.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class UpdateView: View {
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var skipButton: NSButton!
    @IBOutlet weak var installButton: NSButton!
    @IBOutlet weak var remindButton: NSButton!
    
    @IBOutlet weak var packageCountTitle: NSTextField!
    @IBOutlet weak var packageHelpTitle: NSTextField!
}
