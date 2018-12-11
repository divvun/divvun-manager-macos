//
//  SelfUpdateView.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-12-11.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

class SelfUpdateView: View {
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var subtitle: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!

    override func awakeFromNib() {
        // TODO: localise
    }
}
