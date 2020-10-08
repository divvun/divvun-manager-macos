import Foundation
import RxSwift

protocol ConfigFile: Codable {
    associatedtype Key: CodingKey
    mutating func set(key: Self.Key, value: Any?)
    func get(key: Self.Key) -> Any?
    init() // Default initialiser is required
}

fileprivate struct Instathrow : Error {}

class Config<File> where File: ConfigFile {
    let filePath: URL
    
    init(_ path: URL) throws {
        self.filePath = path
        
        // Time for some creation logic
        let fm = FileManager.default
        
        // Assume we might need to create the directory for the thing
        try fm.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Assume the file itself may not exist
        var data: Data
        do {
            data = try Data(contentsOf: path)
            if data.count == 0 {
                throw Instathrow()
            }
        } catch {
            // The file musn't exist then, because data only cares about bytes
            data = "{}".data(using: .utf8)! // empty json file
            fm.createFile(atPath: path.path, contents: data, attributes: nil)
        }
        
        // Try to parse that
        state = try JSONDecoder().decode(File.self, from: data)
    }
    
    private var state: File
    private lazy var changeSubject = { BehaviorSubject<File>(value: state) }()
    
    func save() throws {
        let data = try JSONEncoder().encode(self.state)
        try data.write(to: self.filePath)
    }

    func clear(key: File.Key) throws {
        state.set(key: key, value: nil)
        try self.save()
        changeSubject.onNext(state)
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
