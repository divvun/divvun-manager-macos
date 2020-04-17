//
//  Config.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-04-16.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation
import RxSwift

protocol ConfigFile: Codable {
    associatedtype Key: CodingKey
    mutating func set(key: Self.Key, value: Any?)
    func get(key: Self.Key) -> Any?
    init() // Default initialiser is required
}

class Config<File> where File: ConfigFile {
    let filePath: URL
    
    init(_ path: URL) throws {
        self.filePath = path
        
        // Time for some creation logic
        let fm = FileManager.default
        
        // Assume we might need to create the directory for the thing
        try fm.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Assume the file itself may not exist
        let data: Data
        do {
            data = try Data(contentsOf: path)
        } catch {
            // The file musn't exist then, because data only cares about bytes
            fm.createFile(atPath: path.path, contents: nil, attributes: nil)
            data = Data()
            state = File()
            return
        }
        
        // Try to parse that
        state = try JSONDecoder().decode(File.self, from: data)
    }
    
    private var state = File()
    private lazy var changeSubject = { BehaviorSubject<File>(value: state) }()
    
    func save() throws {
        let data = try JSONEncoder().encode(self.state)
        try data.write(to: self.filePath)
    }
    
    func write<V>(key: File.Key, value: V) throws {
        state.set(key: key, value: value)
        try self.save()
        changeSubject.onNext(state)
    }
    
    func read<V>(key: File.Key) -> V? {
        let v = state.get(key: key)
        if let v = v {
            return v as? V
        } else {
            return nil
        }
    }
    
    func observe<V>(key: File.Key) -> Observable<V?> where V: Equatable {
        return self.changeSubject.map {
            $0.get(key: key) as? V
        }.distinctUntilChanged()
    }
}
