//
//  UserDefaults.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation

protocol UserSettingsJSON {
    var requiresJSON: Bool { get }
    var rawValue: String { get }
}

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
