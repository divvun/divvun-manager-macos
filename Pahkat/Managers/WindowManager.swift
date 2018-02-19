//
//  WindowManager.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift

class WindowManager {
    private var instances = [String: NSWindowController]()
    
    func get<W, T: WindowController<W>>(_ type: T.Type) -> T {
        if let instance = instances[T.windowNibPath] as? T {
            return instance
        }
        
        let instance = T()
        instances[T.windowNibPath] = instance
        return instance
    }
    
    func set<W, T: WindowController<W>>(_ viewController: NSViewController, for type: T.Type) {
        let windowController = get(type)
        windowController.contentWindow.set(viewController: viewController)
    }
    
    func show<Window, T: WindowController<Window>>(_ type: T.Type) {
        get(type).showWindow(nil)
    }
    
    func close<Window, T: WindowController<Window>>(_ type: T.Type) {
        get(type).close()
    }
}
