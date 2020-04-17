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
    let settings: Settings
//    let store = { AppStore() }()
    let windows = { WindowManager() }()
    let packageStore: PahkatClient
    
    init() throws {
        settings = try Settings()
        packageStore = PahkatClient(unixSocketPath: URL(fileURLWithPath: "/tmp/pahkat"))
    }
}

var AppContext: AppContextImpl!

class App: NSApplication {
    private lazy var appDelegate = AppDelegate()
    
    override init() {
        super.init()
        
        self.delegate = appDelegate
        
        do {
            AppContext = try AppContextImpl()
        } catch let error {
            // TODO: show an NSAlert to the user indicating the actual problem and how to fix it
            todo()
        }
        
        let language: String? = AppContext.settings.read(key: .language)
        
        if let language = language {
            UserDefaults.standard.set(language, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    override func terminate(_ sender: Any?) {
        AppContext = nil
        super.terminate(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
