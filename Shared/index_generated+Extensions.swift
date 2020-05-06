import Foundation

struct RefMap<K: Hashable & Encodable, V: Hashable & Encodable>: Equatable, Hashable, Encodable {
    static func == (lhs: RefMap<K, V>, rhs: RefMap<K, V>) -> Bool {
        return lhs.ptr == rhs.ptr
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.ptr)
    }
    
    func encode(to encoder: Encoder) throws {
        var map = [K:V]()
        for i in 0..<count {
            guard let k = keyGetter(i) else { continue }
            map[k] = self[k]
        }
        try map.encode(to: encoder)
    }
    
    private let ptr: UnsafeMutableRawPointer
    private let count: Int32
    private let keyGetter: (Int32) -> K?
    private let valueGetter: (Int32) throws -> V?

    class Values: IteratorProtocol, Sequence {
        typealias Element = V

        private let map: RefMap<K, V>
        private var cur: Int32 = 0

        fileprivate init(_ map: RefMap<K, V>) {
            self.map = map
        }

        func next() -> V? {
            if cur == map.count {
                return nil
            }

            let val = try? map.valueGetter(cur)
            self.cur += 1
            return val
        }
    }

    class Keys: IteratorProtocol, Sequence {
        typealias Element = K

        private let map: RefMap<K, V>
        private var cur: Int32 = 0

        fileprivate init(_ map: RefMap<K, V>) {
            self.map = map
        }

        func next() -> K? {
            if cur == map.count {
                return nil
            }

            let val = map.keyGetter(cur)
            self.cur += 1
            return val
        }
    }
    
    var values: Self.Values {
        Self.Values(self)
    }

    var keys: Self.Keys {
        Self.Keys(self)
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

struct RefList<T: Hashable & Encodable>: Collection, Sequence, Equatable, Encodable {
    typealias Element = T
    typealias Index = Int32
    var startIndex: Int32 { 0 }
    var endIndex: Int32 { Swift.max(0, count - 1) }
    
    private let ptr: UnsafeMutableRawPointer
    private let count: Int32
    private let getter: (Int32) throws -> T?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: self)
    }
    
    var underestimatedCount: Int { Int(count) }
    
    struct Iterator : IteratorProtocol {
        var index: Int32 = -1
        let count: Int32
        
        private let getter: (Int32) throws -> T?
        
        typealias Element = T
        
        mutating func next() -> T? {
            index += 1
            if index > count {
                return nil
            }
            return try? self.getter(index)
        }
        
        fileprivate init(_ getter: @escaping (Int32) throws -> T?, count: Int32) {
            self.getter = getter
            self.count = count - 1
        }
    }
    
    func makeIterator() -> Iterator {
        return Iterator(getter, count: count)
    }
    
    subscript(_ index: Int) -> T? {
        return try? self.getter(Int32(index))
    }
    
    subscript(position: Int32) -> T {
        return self[Int(position)]!
    }
    
    func index(after i: Int32) -> Int32 {
        return Swift.min(endIndex, i)
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

struct WindowsExecutable: Equatable, Hashable, Encodable {}
struct TarballPackage: Equatable, Hashable, Encodable {}

enum SystemTarget: String, Equatable, Hashable, Encodable {
    case system
    case user
}

extension SystemTarget {
    var intValue: UInt32 {
        switch self {
        case .system: return 0
        case .user: return 1
        }
    }
}

extension SystemTarget {
    static func from(int value: UInt32) -> SystemTarget {
        if value == 1 {
            return .user
        } else {
            return .system
        }
    }

    static func from(string value: String) -> SystemTarget {
        switch value {
        case "user":
            return .user
        default:
            return .system
        }
    }
    
    static func from(byte value: UInt8) -> SystemTarget {
        if value == 1 {
            return .user
        } else {
            return .system
        }
    }

    static func from(bitFlags: UInt8) -> Set<SystemTarget> {
        if bitFlags & 0b0000_0001 == 1 {
            return [.system, .user]
        } else {
            return [.system]
        }
    }
}

enum RebootSpec: String, Equatable, Hashable, Encodable {
    case install
    case uninstall
    case update
}

extension RebootSpec {
    static func from(bitFlags: UInt8) -> Set<RebootSpec> {
        var set: Set<RebootSpec> = Set()
        
        if bitFlags & 0b1000_0000 != 0 {
            set.insert(.install)
        }
        
        if bitFlags & 0b0100_0000 != 0 {
            set.insert(.uninstall)
        }
        
        if bitFlags & 0b0010_0000 != 0 {
            set.insert(.update)
        }
        
        return set
    }
}


struct MacOSPackage: Equatable, Hashable, Encodable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    enum Keys: CodingKey {
        case type
        case url
        case pkgId
        case size
        case installedSize
        case targets
        case requiresReboot
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)

        try c.encode("MacOSPackage", forKey: .type)
        try c.encodeIfPresent(url, forKey: .url)
        try c.encodeIfPresent(pkgId, forKey: .pkgId)
        try c.encode(size, forKey: .size)
        try c.encode(installedSize, forKey: .installedSize)
        try c.encode(targets, forKey: .targets)
        try c.encode(requiresReboot, forKey: .requiresReboot)
    }
    
    let inner: pahkat.MacOSPackage
    
    var url: String? { inner.url }
    var pkgId: String? { inner.pkgId }
    var size: UInt64 { inner.size }
    var installedSize: UInt64 { inner.installedSize }
    
    // WORKAROUND LACK OF ENUM BITFLAGS IN RUST
    // flags: MacOSPackageFlag = TargetSystem;
    
    let targets: Set<SystemTarget>
    var requiresReboot: Set<RebootSpec>
    
    
    internal init(_ package: pahkat.MacOSPackage) {
        self.inner = package
        self.targets = SystemTarget.from(bitFlags: package.flags)
        self.requiresReboot = RebootSpec.from(bitFlags: package.flags)
    }
}


enum Payload: Equatable, Hashable, Encodable {
    func encode(to encoder: Encoder) throws {
        switch self {
        case let .macOSPackage(x): try x.encode(to: encoder)
        case let .windowsExecutable(x): try x.encode(to: encoder)
        case let .tarballPackage(x): try x.encode(to: encoder)
        }
    }
    
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


struct Target: Equatable, Hashable, Encodable {
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

    private enum Keys: String, CodingKey {
        case arch
        case dependencies
        case platform
        case payload
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)

        try c.encodeIfPresent(platform, forKey: .platform)
        try c.encodeIfPresent(arch, forKey: .arch)
        try c.encode(dependencies, forKey: .dependencies)
        try c.encodeIfPresent(payload, forKey: .payload)
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
        return inner.platform
    }
}

struct Release: Equatable, Hashable, Encodable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.version == rhs.version
            && lhs.channel == rhs.channel
            && lhs.target == rhs.target
    }

    func hash(into hasher: inout Hasher) {
        todo()
    }

    private enum Keys: CodingKey {
        case version
        case channel
        case authors
        case license
        case licenseUrl
        case target
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)

        try c.encode(version, forKey: .version)
        try c.encodeIfPresent(channel, forKey: .channel)
        try c.encode(authors, forKey: .authors)
        try c.encodeIfPresent(license, forKey: .license)
        try c.encodeIfPresent(licenseUrl, forKey: .licenseUrl)
        try c.encode(target, forKey: .target)
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

struct Descriptor: Equatable, Hashable, Encodable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        todo()
    }

    private enum Keys: CodingKey {
        case id
        case name
        case description
        case tags
        case release
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)

        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encode(tags, forKey: .tags)
        try c.encode(release, forKey: .release)
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

enum Package: Equatable, Hashable, Encodable {
    func encode(to encoder: Encoder) throws {
        switch self {
        case let .concrete(x): try x.encode(to: encoder)
        }
    }

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

