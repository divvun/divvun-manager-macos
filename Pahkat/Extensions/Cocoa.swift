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
