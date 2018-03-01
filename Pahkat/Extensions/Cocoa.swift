//
//  Cocoa.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

extension NSSegmentedControl {
    var selectedSegments: [Int] {
        return (0..<self.segmentCount).flatMap({ self.isSelected(forSegment: $0) ? $0 : nil })
    }
}

extension NSMenuItem {
    convenience init(title: String, target: AnyObject? = nil, action: Selector? = nil) {
        self.init(title: title, action: action, keyEquivalent: "")
        self.target = target
    }
}

extension NSToolbarItem {
    convenience init(view: NSView, identifier: NSToolbarItem.Identifier) {
        self.init(itemIdentifier: identifier)
        self.view = view
    }
}

extension NSToolbar {
    func redraw() {
        // AHHAHAhahahahasdhiuafelhiuafewlihufewhiluafewilhuaefwhio!!!!11111oneoneoneetttetttetetettt
        self.setItems(identifiers: self.items.map { $0.itemIdentifier })
    }
    
    func setItems(_ strings: [String]) {
        self.setItems(identifiers: strings.map { NSToolbarItem.Identifier(rawValue: $0) })
    }
    
    func setItems(identifiers: [NSToolbarItem.Identifier]) {
        for i in (0..<self.items.count).reversed() {
            self.removeItem(at: i)
        }
        
        for i in 0..<identifiers.count {
            self.insertItem(withItemIdentifier: identifiers[i], at: self.items.count)
        }
    }
}
