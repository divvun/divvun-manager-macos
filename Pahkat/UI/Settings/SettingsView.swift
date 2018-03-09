//
//  SettingsView.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class SettingsView: View {
    @IBOutlet weak var frequencyPopUp: NSPopUpButton!
    @IBOutlet weak var frequencyLabel: NSTextField!
    
    @IBOutlet weak var languageDropdown: NSPopUpButton!
    @IBOutlet weak var languageLabel: NSTextField!
    @IBOutlet weak var languageHelpLabel: NSTextField!
    
    @IBOutlet weak var repoTableView: NSTableView!
    @IBOutlet weak var repoLabel: NSTextField!
    
    @IBOutlet weak var repoAddButton: NSButton!
    @IBOutlet weak var repoRemoveButton: NSButton!
    
    @IBOutlet weak var repoChannelColumn: NSPopUpButtonCell!
    
    override func awakeFromNib() {
        frequencyLabel.stringValue = "\(Strings.updateFrequency):"
        languageLabel.stringValue = "\(Strings.interfaceLanguage):"
        languageHelpLabel.stringValue = Strings.restartTheAppForLanguageChanges
        repoLabel.stringValue = "\(Strings.repositories):"
        
        for column in repoTableView.tableColumns {
            let id = column.identifier.rawValue
            column.headerCell.stringValue = Strings.string(for: id)
        }
        
        self.repoTableView.headerView?.needsLayout = true
        
        repoChannelColumn.menu = NSMenu()
    }
}
