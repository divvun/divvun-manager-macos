//
//  App.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import Cocoa
import XCGLogger

let log = XCGLogger.default

class AppContextImpl {
    lazy var client = { PahkatClient()! }()
    lazy var settings = { SettingsStore() }()
    let store = { AppStore() }()
    let windows = { WindowManager() }()
}

var AppContext: AppContextImpl!

class App: NSApplication {
    private lazy var appDelegate = AppDelegate()
    
    override init() {
        super.init()
        
        if UserDefaults.standard.object(forKey: "AppleLanguages") != nil {
            if UserDefaults.standard.string(forKey: "AppleLanguages") == nil {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                UserDefaults.standard.synchronize()
            }
        }
        
        self.delegate = appDelegate
        
        PahkatAdminReceiver()
            .service(errorCallback: { log.debug($0) })
            .xpcServiceVersion(withReply: {
                log.debug("XPC service version: \($0)")
            })
        
        AppContext = AppContextImpl()
    }
    
    override func terminate(_ sender: Any?) {
        AppContext = nil
        super.terminate(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
