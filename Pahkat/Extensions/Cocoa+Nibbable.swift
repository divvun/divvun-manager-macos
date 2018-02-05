//
//  Cocoa+Nibbable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

protocol Nibbable {}

extension NSMenu: Nibbable {}

extension Nibbable where Self: NSUserInterfaceItemIdentification {
    static var nibName: String {
        return String(describing: self)
    }
    
    static func loadFromNib(named nibName: String? = nil) -> Self {
        let bundle = Bundle(for: Self.self)
        
        var views: NSArray? = NSArray()
        
        if let nib = NSNib(nibNamed: NSNib.Name(rawValue: nibName ?? Self.nibName), bundle: bundle) {
            nib.instantiate(withOwner: nil, topLevelObjects: &views)
        }
        
        guard let view = views?.first(where: { $0 is Self }) as? Self else {
            fatalError("Nib could not be loaded for nibName: \(self.nibName); check that the XIB owner has been set to the given view: \(self)")
        }
        
        return view
    }
}

class ViewController<T: NSView>: NSViewController where T: Nibbable {
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
