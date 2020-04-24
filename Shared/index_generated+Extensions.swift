//
//  index_generated+Extensions.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-04-16.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation

struct RefMap<K: Hashable, V: Hashable>: Equatable, Hashable {
    static func == (lhs: RefMap<K, V>, rhs: RefMap<K, V>) -> Bool {
        return lhs.ptr == rhs.ptr
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.ptr)
    }
    
    private let ptr: UnsafeMutableRawPointer
    private let count: Int32
    private let keyGetter: (Int32) -> K?
    private let valueGetter: (Int32) throws -> V?

    struct Values {
        private let map: RefMap<K, V>
        
        @inlinable public func forEach(_ body: (V) throws -> Void) rethrows {
            try (0..<self.map.count).forEach {
                try body(self.map.valueGetter($0)!)
            }
        }

        func contains(_ value: V) -> Bool {
            for i in 0 ..< self.map.count {
                if let contains = try? self.map.valueGetter(i) == value,
                    contains == true {
                    return true
                }
            }
            return false
        }
        
        fileprivate init(_ map: RefMap<K, V>) {
            self.map = map
        }
    }
    
    var values: Self.Values {
        Self.Values(self)
    }
    
    subscript(_ key: K) -> V? {
        for i in 0..<count {
            if keyGetter(i) == key {
                return try? valueGetter(i)
            }
        }
        
        return nil
    }
    
    public init(ptr: UnsafeMutableRawPointer, count: Int32, keyGetter: @escaping (Int32) -> K?, valueGetter: @escaping (Int32) throws -> V?) {
        self.ptr = ptr
        self.count = count
        self.keyGetter = keyGetter
        self.valueGetter = valueGetter
    }
}

struct RefList<T: Hashable>: Sequence, Equatable {
    typealias Element = T
    
    private let ptr: UnsafeMutableRawPointer
    private let count: Int32
    private let getter: (Int32) throws -> T?
    
    var underestimatedCount: Int { Int(count) }

    var lastItem: T {
        try! self.getter(count-1)!
    }
    
    struct Iterator : IteratorProtocol {
        var count: Int32 = -1
        private let getter: (Int32) throws -> T?
        
        typealias Element = T
        
        mutating func next() -> T? {
            count += 1
            return try? self.getter(count)
        }
        
        fileprivate init(_ getter: @escaping (Int32) throws -> T?) {
            self.getter = getter
        }
    }
    
    func makeIterator() -> Iterator {
        return Iterator(getter)
    }
    
    subscript(_ index: Int) -> T? {
        return try? self.getter(Int32(index))
    }
    
    static func == (lhs: RefList<T>, rhs: RefList<T>) -> Bool {
        return lhs.ptr == rhs.ptr
    }

    public init(ptr: UnsafeMutableRawPointer, count: Int32, getter: @escaping (Int32) throws -> T?) {
        self.ptr = ptr
        self.count = count
        self.getter = getter
    }
}

extension pahkat.Descriptor {
    var release: RefList<Release> {
        RefList(ptr: self.__buffer.memory, count: self.releaseCount) { (i) in
            return try self.release(at: i).map { try Release($0, descriptor: Descriptor(self)) }
        }
    }
    
    var tags: RefList<String> {
        RefList(ptr: self.__buffer.memory, count: self.tagsCount) { (i) in
            return self.tags(at: i)
        }
    }

    var name: RefMap<String, String> {
        RefMap(ptr: self.__buffer.memory, count: self.nameKeysCount, keyGetter: { (i) in
            self.nameKeys(at: i)
        }) { (i) in
            self.nameValues(at: i)
        }
    }
    
    var description: RefMap<String, String> {
        RefMap(ptr: self.__buffer.memory, count: self.descriptionKeysCount, keyGetter: { (i) in
            self.descriptionKeys(at: i)
        }) { (i) in
            self.descriptionValues(at: i)
        }
    }
}

extension pahkat.Release {
    var authors: RefList<String> {
        RefList(ptr: self.__buffer.memory, count: self.authorsCount) { (i) in
            return self.authors(at: i)
        }
    }
    
    var target: RefList<Target> {
        RefList(ptr: self.__buffer.memory, count: self.targetCount) { (i) in
            return self.target(at: i).map { Target($0) }
        }
    }
}

struct WindowsExecutable: Equatable, Hashable {}
struct TarballPackage: Equatable, Hashable {}

enum SystemTarget: UInt8, Equatable, Hashable {
    case system = 0
    case user = 1
}

enum RebootRequirement: Equatable, Hashable {
    case install
    case uninstall
}

struct MacOSPackage: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    let inner: pahkat.MacOSPackage
    
    var url: String? { inner.url }
    var pkgId: String? { inner.pkgId }
    var size: UInt64 { inner.size }
    var installedSize: UInt64 { inner.installedSize }
    // WORKAROUND LACK OF ENUM BITFLAGS IN RUST
    // flags: MacOSPackageFlag = TargetSystem;
    
    let targets: Set<SystemTarget>
    var requiresReboot: Set<RebootRequirement>
    
    
    internal init(_ package: pahkat.MacOSPackage) {
        self.inner = package
        self.targets = Set() // todo()
        self.requiresReboot = Set() // todo()
    }
}


enum Payload: Equatable, Hashable {
    case windowsExecutable(WindowsExecutable)
    case macOSPackage(MacOSPackage)
    case tarballPackage(TarballPackage)
}

extension pahkat.Target {
    var dependencies: RefMap<String, String> {
        RefMap(ptr: self.__buffer.memory, count: self.dependenciesKeysCount, keyGetter: { (i) in
            self.dependenciesKeys(at: i)
        }) { (i) in
            self.dependenciesValues(at: i)
        }
    }
}


struct Target: Equatable, Hashable {
    private let inner: pahkat.Target

    internal init(_ target: pahkat.Target) {
        self.inner = target
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.platform == rhs.platform
            && lhs.arch == rhs.arch
            && lhs.dependencies == rhs.dependencies
    }
    
    func hash(into hasher: inout Hasher) {
        todo()
    }
    
    var arch: String? { inner.arch }
    var dependencies: RefMap<String, String> { inner.dependencies }
    var payload: Payload? {
        switch inner.payloadType {
        case .tarballpackage:
            return Payload.tarballPackage(TarballPackage())
        case .windowsexecutable:
            return Payload.windowsExecutable(WindowsExecutable())
        case .macospackage:
            guard let x = inner.payload(type: pahkat.MacOSPackage.self) else {
                return nil
            }
            return Payload.macOSPackage(MacOSPackage(x))
        default:
            return nil
        }
    }
    var platform: String? {
        return "macos" // FIXME: using inner.platform causes a crash
    }
}

struct Release: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.version == rhs.version
            && lhs.channel == rhs.channel
            && lhs.target == rhs.target
    }

    func hash(into hasher: inout Hasher) {
        todo()
    }
    
    private let inner: pahkat.Release
    
    let version: String
    var channel: String? { inner.channel }
    var authors: RefList<String> { inner.authors }
    var license: String? { inner.license }
    var licenseUrl: String? { inner.licenseUrl }
    var target: RefList<Target> { inner.target }
    var macosTarget: Target? {
        return self.target.first(where: { $0.platform == "macos" })
    }
    
    internal init(_ release: pahkat.Release, descriptor: Descriptor) throws {
        self.inner = release
        guard let version = release.version else {
            throw LoadedRepositoryError.missingVersion(inner, descriptor)
        }
        
        self.version = version
    }
}

struct Descriptor: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        todo()
    }
    
    private let inner: pahkat.Descriptor
    
    let id: String
    var release: RefList<Release> { inner.release }
    var name: RefMap<String, String> { inner.name }
    var description: RefMap<String, String> { inner.description }
    var tags: RefList<String> { inner.tags }
    
    internal init(_ descriptor: pahkat.Descriptor) throws {
        self.inner = descriptor
        
        guard let id = descriptor.id else {
            throw LoadedRepositoryError.missingDescriptorID(inner)
        }
        
        self.id = id
    }
}

enum Package: Equatable, Hashable {
    case concrete(Descriptor)
//    case synthetic
//    case redirect
}


extension pahkat.Packages {
    var packages: RefMap<String, Package> {
        assert(self.packagesValuesCount == self.packagesKeysCount, "Packages must have same number of keys and values")
        
        let descriptorCallback = { (index: Int32) in
            try self.packagesValues(at: index).map {
                Package.concrete(try Descriptor($0))
            }
        }
        
        return RefMap<String, Package>(
            ptr: self.__buffer.memory,
            count: self.packagesKeysCount,
            keyGetter: self.packagesKeys,
            valueGetter: descriptorCallback)
    }

    var descriptors: RefMap<String, Descriptor> {
        assert(self.packagesValuesCount == self.packagesKeysCount, "Packages must have same number of keys and values")

        let descriptorCallback = { (index: Int32) in
            try self.packagesValues(at: index).map {
                try Descriptor($0)
            }
        }

        return RefMap<String, Descriptor>(
            ptr: self.__buffer.memory,
            count: self.packagesKeysCount,
            keyGetter: self.packagesKeys,
            valueGetter: descriptorCallback)
    }

}

struct Packages: Equatable, Hashable, Packageable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        todo()
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        todo()
    }
    
    private let inner: pahkat.Packages
    
    var packages: RefMap<String, Package> { inner.packages }
    var descriptors: RefMap<String, Descriptor> { inner.descriptors }

    internal init(_ packages: pahkat.Packages) {
        self.inner = packages
    }
}

protocol Packageable {
    var packages: RefMap<String, Package> { get }
    var descriptors: RefMap<String, Descriptor> { get }
}

