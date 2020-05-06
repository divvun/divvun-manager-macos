//
//  LandingView.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-02-07.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Cocoa
import WebKit

class LandingView: View {
    @IBOutlet weak var primaryLabel: NSTextField!
    @IBOutlet weak var primaryButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    
    var webView: WKWebView!
    
    override func awakeFromNib() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), configuration: config)
        self.autoresizesSubviews = true
        webView.autoresizingMask = [.height, .width]
        self.addSubview(webView)
        
        primaryLabel.stringValue = Strings.appName
        primaryButton.title = "Detailed…"
    }
}

