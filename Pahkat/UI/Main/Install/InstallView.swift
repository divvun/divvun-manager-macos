//
//  InstallView.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-19.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class InstallView: View {
    @IBOutlet weak var spinningIndicator: NSProgressIndicator!
    @IBOutlet weak var horizontalIndicator: NSProgressIndicator!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var remainingLabel: NSTextField!
    @IBOutlet weak var primaryLabel: NSTextField!
    @IBOutlet weak var primaryButton: NSButton!
    
    override func awakeFromNib() {
        horizontalIndicator.controlTint = .blueControlTint
        
        spinningIndicator.isIndeterminate = true
        spinningIndicator.usesThreadedAnimation = true
        spinningIndicator.startAnimation(nil)
    }
}
