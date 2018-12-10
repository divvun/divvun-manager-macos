//
//  App.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import Cocoa

class App: NSApplication {
    private lazy var appDelegate = AppDelegate()
    
    override init() {
        super.init()
        
        self.delegate = appDelegate
        
        PahkatAdminReceiver().service(errorCallback: { print($0) }).xpcServiceVersion(withReply: {
            print("XPC service version: \($0)")
        })
    }
    
    override func terminate(_ sender: Any?) {
//        AppContext.rpc.pahkatcIPC.terminate()
//        AppContext.rpc.pahkatcIPC.waitUntilExit()
        super.terminate(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
