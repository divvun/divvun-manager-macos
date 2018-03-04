//
//  Cocoa.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

extension UserDefaults {
    func get<T>(_ key: String) -> T? {
        return self.object(forKey: key) as? T
    }
    
    func get<T: Codable>(json key: UserSettingsJSON, type: T.Type) -> T? {
        if key.requiresJSON {
            return self[json: key.rawValue]
        } else {
            return self[key.rawValue]
        }
    }
    
    func set<T: Codable>(json key: UserSettingsJSON, value: T) {
        if key.requiresJSON {
            self[json: key.rawValue] = value
        } else {
            self[key.rawValue] = value
        }
    }
    
    func getArray<T>(_ key: String) -> [T]? {
        return self.array(forKey: key) as? [T]
    }
    
    subscript<T>(_ key: String) -> T? {
        get { return self.get(key) }
        set(value) { self.set(value, forKey: key) }
    }
    
    subscript<T: Codable>(_ key: UserSettingsJSON) -> T? {
        get { return self.get(json: key, type: T.self) }
        set(value) { self.set(json: key, value: value) }
    }
    
    subscript<T: Codable>(json key: String) -> T? {
        get {
            if let data = self.data(forKey: key) {
                return try? JSONDecoder().decode(T.self, from: data)
            }
            return nil
        }
        set(value) {
            if let value = value {
                self.set(try? JSONEncoder().encode(value), forKey: key)
            } else {
                self.set(nil, forKey: key)
            }
        }
    }
}

extension Process {
    @discardableResult
    static func run(_ url: URL, arguments: [String], terminationHandler: ((Process) -> Swift.Void)? = nil) throws -> Process {
        let process = Process()
        process.launchPath = url.path
        process.arguments = arguments
        process.terminationHandler = terminationHandler
        process.launch()
        return process
    }
}

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
    
    convenience init(title: String, value: Any, target: AnyObject? = nil, action: Selector? = nil) {
        self.init(title: title, target: target, action: action)
        self.representedObject = value
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
