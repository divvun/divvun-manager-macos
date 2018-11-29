//
//  Constants.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum PahkatAppleEvent: UInt32 {
    static let classID: UInt32 = 0x504B4854 // "PHKT"
    case update = 0x504B5430 // "PKT0"
    case restartApp = 0x504B5431 // "PKT1"
    case message = 0x504B5432 // "PKT2"
    
    var stringValue: String {
        switch self {
        case .update:
            return "update"
        case .restartApp:
            return "restartApp"
        case .message:
            return "message"
        }
    }
}

class PahkatIPC: NSObject {
    override init() {
        super.init()
        
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleMessage(_:withReplyEvent:)),
            forEventClass: PahkatAppleEvent.classID,
            andEventID: PahkatAppleEvent.message.rawValue)
    }
    
    @objc func handleMessage(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventManager) {
        
    }
}
