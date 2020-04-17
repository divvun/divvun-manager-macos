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
    
    fileprivate init(ptr: UnsafeMutableRawPointer, count: Int32, keyGetter: @escaping (Int32) -> K?, valueGetter: @escaping (Int32) throws -> V?) {
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
    private let getter: (Int32) -> T?
    
    var underestimatedCount: Int { Int(count) }
    
    struct Iterator : IteratorProtocol {
        var count: Int32 = -1
        private let getter: (Int32) -> T?
        
        typealias Element = T
        
        mutating func next() -> T? {
            count += 1
            return self.getter(count)
        }
        
        fileprivate init(_ getter: @escaping (Int32) -> T?) {
            self.getter = getter
        }
    }
    
    func makeIterator() -> Iterator {
        return Iterator(getter)
    }
    
    subscript(_ index: Int) -> T? {
        return self.getter(Int32(index))
    }
    
    static func == (lhs: RefList<T>, rhs: RefList<T>) -> Bool {
        return lhs.ptr == rhs.ptr
    }
}

extension pahkat.Descriptor {
    var release: RefList<Release> {
        todo()
    }
    
    var tags: RefList<String> {
        todo()
    }
    
    var name: RefMap<String, String> {
        todo()
    }
    
    var description: RefMap<String, String> {
        todo()
    }
}

extension pahkat.Release {
    var authors: RefList<String> {
        todo()
    }
    
    var target: RefList<Target> {
        todo()
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
        todo()
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        todo()
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
        todo()
    }
}


struct Target: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        todo()
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        todo()
    }
    
    private let inner: pahkat.Target
    
    var platform: String? { inner.platform }
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
    
    internal init(_ target: pahkat.Target) {
        self.inner = target
    }
}

struct Release: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        todo()
        return true
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
        todo()
        return true
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
}

struct Packages: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        todo()
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        todo()
    }
    
    private let inner: pahkat.Packages
    
    var packages: RefMap<String, Package> { inner.packages }
    
    internal init(_ packages: pahkat.Packages) {
        self.inner = packages
    }
}
