import Foundation
import RxSwift

public struct Repository: Hashable, Codable {
    let _type: _Type?
    let agent: RepositoryAgent?
    let base: URL
    let name: [String: String]
    let description: [String: String]
    let primaryFilter: PrimaryFilter
    let channels: [Channels]
    let categories: [String: [String: String]]

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v ^= agent?.hashValue ?? 0
        v ^= base.hashValue
        v += name.count
        v += description.count
        v ^= primaryFilter.hashValue
        v += channels.count
        return v
    }

    public static func ==(lhs: Repository, rhs: Repository) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.agent == nil && rhs.agent != nil { return false }
        if lhs.agent != nil && rhs.agent == nil { return false }
        if let lv = lhs.agent, let rv = rhs.agent, lv != rv { return false }
        if lhs.base != rhs.base { return false }
        if lhs.name != rhs.name { return false }
        if lhs.description != rhs.description { return false }
        if lhs.primaryFilter != rhs.primaryFilter { return false }
        if lhs.channels != rhs.channels { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case agent = "agent"
        case base = "base"
        case name = "name"
        case description = "description"
        case primaryFilter = "primaryFilter"
        case channels = "channels"
        case categories = "categories"
    }

    public enum _Type: String, Codable {
        case repository = "Repository"
    }

    public enum PrimaryFilter: String, Codable {
        case category = "category"
        case language = "language"
    }

    public enum Channels: String, Codable {
        case stable = "stable"
        case beta = "beta"
        case alpha = "alpha"
        case nightly = "nightly"
    }
}

public struct RepositoryAgent: Hashable, Codable {
    let name: String
    let version: String
    let url: URL?

    public var hashValue: Int {
        var v = 0
        v ^= name.hashValue
        v ^= version.hashValue
        v ^= url?.hashValue ?? 0
        return v
    }

    public static func ==(lhs: RepositoryAgent, rhs: RepositoryAgent) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.version != rhs.version { return false }
        if lhs.url == nil && rhs.url != nil { return false }
        if lhs.url != nil && rhs.url == nil { return false }
        if let lv = lhs.url, let rv = rhs.url, lv != rv { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case version = "version"
        case url = "url"
    }

}

public struct Packages: Hashable, Codable {
    let _type: _Type?
    let base: URL
    let packages: [String: Package]

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v += packages.count
        return v
    }

    public static func ==(lhs: Packages, rhs: Packages) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.packages != rhs.packages { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case packages = "packages"
        case base = "base"
    }

    public enum _Type: String, Codable {
        case packages = "Packages"
    }
}

public struct Package: Hashable, Codable {
    let _type: _Type?
    let id: String
    let name: [String: String]
    let description: [String: String]
    let version: String
    let category: String
    let languages: [String]
    let platform: [String: String]
    let dependencies: [String: String]
    let virtualDependencies: [String: String]
    let installer: Installer

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v ^= id.hashValue
        v += name.count
        v += description.count
        v ^= version.hashValue
        v ^= category.hashValue
        v += languages.count
        v += platform.count
        v += dependencies.count
        v += virtualDependencies.count
        v ^= installer.hashValue
        return v
    }

    public static func ==(lhs: Package, rhs: Package) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        if lhs.description != rhs.description { return false }
        if lhs.version != rhs.version { return false }
        if lhs.category != rhs.category { return false }
        if lhs.languages != rhs.languages { return false }
        if lhs.platform != rhs.platform { return false }
        if lhs.dependencies != rhs.dependencies { return false }
        if lhs.virtualDependencies != rhs.virtualDependencies { return false }
        if lhs.installer != rhs.installer { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case id = "id"
        case name = "name"
        case description = "description"
        case version = "version"
        case category = "category"
        case languages = "languages"
        case platform = "platform"
        case dependencies = "dependencies"
        case virtualDependencies = "virtualDependencies"
        case installer = "installer"
    }

    public enum _Type: String, Codable {
        case package = "Package"
    }

    public enum Installer: Hashable, Codable {
        case windowsInstaller(WindowsInstaller)
        case macOsInstaller(MacOsInstaller)
        case tarballInstaller(TarballInstaller)

        public static func ==(lhs: Installer, rhs: Installer) -> Bool {
            switch (lhs, rhs) {
            case let (.windowsInstaller(a), .windowsInstaller(b)):
                return a == b
            case let (.macOsInstaller(a), .macOsInstaller(b)):
                return a == b
            case let (.tarballInstaller(a), .tarballInstaller(b)):
                return a == b
            default:
                return false
            }
        }

        public var hashValue: Int {
            switch self {
            case let .windowsInstaller(value):
                return value.hashValue
            case let .macOsInstaller(value):
                return value.hashValue
            case let .tarballInstaller(value):
                return value.hashValue
            }
        }

        private enum CodingKeys: String, CodingKey {
            case discriminator = "@type"
        }

        private enum DiscriminatorKeys: String, Codable {
            case windowsInstaller = "WindowsInstaller"
            case macOsInstaller = "MacOSInstaller"
            case tarballInstaller = "TarballInstaller"
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .windowsInstaller(value):
                try container.encode(value)
            case let .macOsInstaller(value):
                try container.encode(value)
            case let .tarballInstaller(value):
                try container.encode(value)
            }
        }

        public init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer()
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try values.decode(DiscriminatorKeys.self, forKey: .discriminator)

            switch discriminator {
            case .windowsInstaller:
                self = .windowsInstaller(try value.decode(WindowsInstaller.self))
            case .macOsInstaller:
                self = .macOsInstaller(try value.decode(MacOsInstaller.self))
            case .tarballInstaller:
                self = .tarballInstaller(try value.decode(TarballInstaller.self))
            }
        }
    }
}

public struct TarballInstaller: Hashable, Codable {
    let _type: _Type?
    let url: URL
    let size: UInt64
    let installedSize: UInt64

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v ^= url.hashValue
        v ^= size.hashValue
        v ^= installedSize.hashValue
        return v
    }

    public static func ==(lhs: TarballInstaller, rhs: TarballInstaller) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.url != rhs.url { return false }
        if lhs.size != rhs.size { return false }
        if lhs.installedSize != rhs.installedSize { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case url = "url"
        case size = "size"
        case installedSize = "installedSize"
    }

    public enum _Type: String, Codable {
        case tarballInstaller = "TarballInstaller"
    }
}

public struct WindowsInstaller: Hashable, Codable {
    let _type: _Type?
    let url: URL
    let type: Type_?
    let args: String?
    let uninstallArgs: String?
    let productCode: String
    let requiresReboot: Bool
    let requiresUninstallReboot: Bool
    let size: UInt64
    let installedSize: UInt64

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v ^= url.hashValue
        v ^= type?.hashValue ?? 0
        v ^= args?.hashValue ?? 0
        v ^= uninstallArgs?.hashValue ?? 0
        v ^= productCode.hashValue
        v ^= requiresReboot.hashValue
        v ^= requiresUninstallReboot.hashValue
        v ^= size.hashValue
        v ^= installedSize.hashValue
        return v
    }

    public static func ==(lhs: WindowsInstaller, rhs: WindowsInstaller) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.url != rhs.url { return false }
        if lhs.type == nil && rhs.type != nil { return false }
        if lhs.type != nil && rhs.type == nil { return false }
        if let lv = lhs.type, let rv = rhs.type, lv != rv { return false }
        if lhs.args == nil && rhs.args != nil { return false }
        if lhs.args != nil && rhs.args == nil { return false }
        if let lv = lhs.args, let rv = rhs.args, lv != rv { return false }
        if lhs.uninstallArgs == nil && rhs.uninstallArgs != nil { return false }
        if lhs.uninstallArgs != nil && rhs.uninstallArgs == nil { return false }
        if let lv = lhs.uninstallArgs, let rv = rhs.uninstallArgs, lv != rv { return false }
        if lhs.productCode != rhs.productCode { return false }
        if lhs.requiresReboot != rhs.requiresReboot { return false }
        if lhs.requiresUninstallReboot != rhs.requiresUninstallReboot { return false }
        if lhs.size != rhs.size { return false }
        if lhs.installedSize != rhs.installedSize { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case url = "url"
        case type = "type"
        case args = "args"
        case uninstallArgs = "uninstallArgs"
        case productCode = "productCode"
        case requiresReboot = "requiresReboot"
        case requiresUninstallReboot = "requiresUninstallReboot"
        case size = "size"
        case installedSize = "installedSize"
    }

    public enum _Type: String, Codable {
        case windowsInstaller = "WindowsInstaller"
    }

    public enum Type_: String, Codable {
        case msi = "msi"
        case inno = "inno"
        case nsis = "nsis"
    }
}

public struct MacOsInstaller: Hashable, Codable {
    let _type: _Type?
    let url: URL
    let pkgId: String
    let targets: [Targets]
    let requiresReboot: Bool
    let requiresUninstallReboot: Bool
    let size: UInt64
    let installedSize: UInt64

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v ^= url.hashValue
        v ^= pkgId.hashValue
        v += targets.count
        v ^= requiresReboot.hashValue
        v ^= requiresUninstallReboot.hashValue
        v ^= size.hashValue
        v ^= installedSize.hashValue
        return v
    }

    public static func ==(lhs: MacOsInstaller, rhs: MacOsInstaller) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.url != rhs.url { return false }
        if lhs.pkgId != rhs.pkgId { return false }
        if lhs.targets != rhs.targets { return false }
        if lhs.requiresReboot != rhs.requiresReboot { return false }
        if lhs.requiresUninstallReboot != rhs.requiresUninstallReboot { return false }
        if lhs.size != rhs.size { return false }
        if lhs.installedSize != rhs.installedSize { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case url = "url"
        case pkgId = "pkgId"
        case targets = "targets"
        case requiresReboot = "requiresReboot"
        case requiresUninstallReboot = "requiresUninstallReboot"
        case size = "size"
        case installedSize = "installedSize"
    }

    public enum _Type: String, Codable {
        case macOsInstaller = "MacOSInstaller"
    }

    public enum Targets: String, Codable {
        case system = "system"
        case user = "user"
    }
}

public struct Virtuals: Hashable, Codable {
    let _type: _Type?
    let virtuals: [String: String]

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v += virtuals.count
        return v
    }

    public static func ==(lhs: Virtuals, rhs: Virtuals) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.virtuals != rhs.virtuals { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case virtuals = "virtuals"
    }

    public enum _Type: String, Codable {
        case virtuals = "Virtuals"
    }
}

public struct Virtual: Hashable, Codable {
    let _type: _Type?
    let virtual: Bool
    let id: String
    let name: [String: String]
    let description: [String: String]
    let version: String
    let url: URL
    let target: VirtualTarget

    public var hashValue: Int {
        var v = 0
        v ^= _type?.hashValue ?? 0
        v ^= virtual.hashValue
        v ^= id.hashValue
        v += name.count
        v += description.count
        v ^= version.hashValue
        v ^= url.hashValue
        v ^= target.hashValue
        return v
    }

    public static func ==(lhs: Virtual, rhs: Virtual) -> Bool {
        if lhs._type == nil && rhs._type != nil { return false }
        if lhs._type != nil && rhs._type == nil { return false }
        if let lv = lhs._type, let rv = rhs._type, lv != rv { return false }
        if lhs.virtual != rhs.virtual { return false }
        if lhs.id != rhs.id { return false }
        if lhs.name != rhs.name { return false }
        if lhs.description != rhs.description { return false }
        if lhs.version != rhs.version { return false }
        if lhs.url != rhs.url { return false }
        if lhs.target != rhs.target { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case virtual = "virtual"
        case id = "id"
        case name = "name"
        case description = "description"
        case version = "version"
        case url = "url"
        case target = "target"
    }

    public enum _Type: String, Codable {
        case virtual = "Virtual"
    }
}

public struct VirtualTarget: Hashable, Codable {
    let registryKey: RegistryKey

    public var hashValue: Int {
        var v = 0
        v ^= registryKey.hashValue
        return v
    }

    public static func ==(lhs: VirtualTarget, rhs: VirtualTarget) -> Bool {
        if lhs.registryKey != rhs.registryKey { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case registryKey = "registryKey"
    }

}

public struct RegistryKey: Hashable, Codable {
    let path: String
    let name: String?
    let value: String?
    let valueKind: ValueKind?

    public var hashValue: Int {
        var v = 0
        v ^= path.hashValue
        v ^= name?.hashValue ?? 0
        v ^= value?.hashValue ?? 0
        v ^= valueKind?.hashValue ?? 0
        return v
    }

    public static func ==(lhs: RegistryKey, rhs: RegistryKey) -> Bool {
        if lhs.path != rhs.path { return false }
        if lhs.name == nil && rhs.name != nil { return false }
        if lhs.name != nil && rhs.name == nil { return false }
        if let lv = lhs.name, let rv = rhs.name, lv != rv { return false }
        if lhs.value == nil && rhs.value != nil { return false }
        if lhs.value != nil && rhs.value == nil { return false }
        if let lv = lhs.value, let rv = rhs.value, lv != rv { return false }
        if lhs.valueKind == nil && rhs.valueKind != nil { return false }
        if lhs.valueKind != nil && rhs.valueKind == nil { return false }
        if let lv = lhs.valueKind, let rv = rhs.valueKind, lv != rv { return false }

        return true
    }

    private enum CodingKeys: String, CodingKey {
        case path = "path"
        case name = "name"
        case value = "value"
        case valueKind = "valueKind"
    }

    public enum ValueKind: String, Codable {
        case string = "string"
        case dword = "dword"
        case qword = "qword"
        case etc = "etc"
    }
}
