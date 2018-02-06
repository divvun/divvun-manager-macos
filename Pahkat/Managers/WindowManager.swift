//
//  WindowManager.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift

//protocol WindowConfig<T>: class {
//    let windowType: T.Type
//    let instance: NSWindow
//}


class WindowManager {
    private var instances = [String: NSWindowController]()
    
    func get<T: WindowControllerType>(_ type: T.Type) -> T {
        if let instance = instances[T.windowNibPath] as? T {
            return instance
        }
        
        let instance = T()
        guard let nsInstance = instance as? NSWindowController else {
            fatalError("wat")
        }
        instances[T.windowNibPath] = nsInstance
        return instance
    }
    
    func show<Window, T: WindowController<Window>>(_ type: T.Type) {
        get(type).showWindow(nil)
    }
    
    func close<Window, T: WindowController<Window>>(_ type: T.Type) {
        get(type).close()
    }
}


