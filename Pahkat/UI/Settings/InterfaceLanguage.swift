//
//  InterfaceLanguage.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-05-06.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Cocoa

enum InterfaceLanguage: String, Comparable {
    case systemLocale = ""
    case en = "en"
    case nb = "nb"
    case nn = "nn"
    case nnRunic = "nn-Runr"
    case se = "se"

    var description: String {
        if self == .systemLocale {
            return Strings.systemLocale
        }

        if self == .nnRunic {
            return "ᚿᛦᚿᚮᚱᛌᚴ"
        }

        return ISO639.get(tag: self.rawValue)?.autonymOrName ?? self.rawValue
    }

    static func <(lhs: InterfaceLanguage, rhs: InterfaceLanguage) -> Bool {
        return lhs.description < rhs.description
    }

    private static func createMenuItem(_ thingo: InterfaceLanguage) -> NSMenuItem {
        return NSMenuItem(title: thingo.description, value: thingo)
    }

    static func asMenuItems() -> [NSMenuItem] {
        var x = [
            InterfaceLanguage.en,
            InterfaceLanguage.nb,
            InterfaceLanguage.nn,
            InterfaceLanguage.nnRunic,
            InterfaceLanguage.se
        ].sorted()

        x.insert(InterfaceLanguage.systemLocale, at: 0)

        return x.map { createMenuItem($0) }
    }

    static func bind(to menu: NSMenu) {
        self.asMenuItems().forEach(menu.addItem(_:))
    }
}
