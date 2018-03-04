//
//  WindowManager.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift

class WindowManager: NSObject, NSWindowDelegate {
    private var instances = [String: NSWindowController]()
    
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        if let (key, window) = instances.first(where: { $0.1.window === closingWindow }) {
            instances.removeValue(forKey: key)
        }
        
        // We handle app termination requirements here
        if instances.isEmpty && AppDelegate.instance.applicationShouldTerminateAfterLastWindowClosed(NSApp) {
            defer {
                NSApp.terminate(NSApp)
            }
        }
    }
    
    func get<W, T: WindowController<W>>(_ type: T.Type) -> T {
        if let instance = instances[T.windowNibPath] as? T {
            return instance
        }
        
        let instance = T()
        instances[T.windowNibPath] = instance
        instance.window?.delegate = self
        return instance
    }
    
    func set<W, T: WindowController<W>>(_ viewController: NSViewController, for type: T.Type) {
        let windowController = get(type)
        windowController.contentWindow.set(viewController: viewController)
    }
    
    func show<Window, T: WindowController<Window>>(_ type: T.Type, viewController: NSViewController? = nil) {
        let windowController = get(type)
        windowController.showWindow(nil)
        if let viewController = viewController {
            windowController.contentWindow.set(viewController: viewController)
        }
    }
    
    func close<Window, T: WindowController<Window>>(_ type: T.Type) {
        get(type).close()
        instances.removeValue(forKey: T.windowNibPath)
    }
}
