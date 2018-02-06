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
    
    func get<Window, T: WindowController<Window>>(_ type: Window.Type) -> T {
        if let instance = instances[type.nibPath] as? T {
            return instance
        }
        
        let instance = T()
        instances[type.nibPath] = instance
        return instance
    }
    
    func show<Window, T: WindowController<Window>>(_ type: Window.Type) {
        get(type).showWindow(nil)
    }
    
    func close<Window, T: WindowController<Window>>(_ type: Window.Type) {
        get(type).close()
    }
}


