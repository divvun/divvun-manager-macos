//
//  Cocoa+Nibbable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

protocol Nibbable {}

class View: NSView, Nibbable {}
class ViewController<T: View>: NSViewController {
    let contentView = T.loadFromNib()
    
    override func loadView() {
        view = contentView
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Window: NSWindow, Nibbable {
}

class WindowController<T: Window>: NSWindowController {
    static var windowNibPath: String { return T.nibPath }
    
    let contentWindow = T.loadFromNib()
    
    var viewController: NSViewController? {
        didSet {
            if let v = viewController {
                contentWindow.contentView = v.view
                contentWindow.bind(.title, to: v, withKeyPath: "title", options: nil)
            } else {
                contentWindow.contentView = nil
                contentWindow.unbind(.title)
            }
        }
    }
    
    required init() {
        super.init(window: contentWindow)
        let name = NSWindow.FrameAutosaveName(rawValue: T.nibPath)
        self.shouldCascadeWindows = false
        contentWindow.setFrameUsingName(name)
        contentWindow.setFrameAutosaveName(name)
        self.windowWillLoad()
        self.windowDidLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NSMenu: Nibbable {}
extension Nibbable where Self: NSUserInterfaceItemIdentification {
    static var nibPath: String {
        return String(describing: self)
    }
    
    static func loadFromNib(path nibPath: String = Self.nibPath) -> Self {
        let bundle = Bundle(for: Self.self)
        
        var views: NSArray? = NSArray()
        
        if let nib = NSNib(nibNamed: NSNib.Name(rawValue: nibPath), bundle: bundle) {
            nib.instantiate(withOwner: nil, topLevelObjects: &views)
        }
        
        guard let view = views?.first(where: { $0 is Self }) as? Self else {
            fatalError("Nib could not be loaded for nibPath: \(nibPath); check that the Custom Class for the XIB has been set to the given view: \(self)")
        }
        
        return view
    }
}


