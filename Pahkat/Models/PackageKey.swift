import Foundation

struct PackageKeyParams: Equatable, Hashable {
    private(set) var platform: String?
    private(set) var arch: String?
    private(set) var version: String?
    private(set) var channel: String?
    
    init?(queryItems: [URLQueryItem]) {
        for item in queryItems {
            let name = item.name
            let value = item.value
            
            switch name {
            case "platform":
                self.platform = value
            case "arch":
                self.arch = value
            case "version":
                self.version = value
            case "channel":
                self.channel = value
            default:
                continue
            }
        }
        
        if platform == nil && arch == nil && version == nil && channel == nil {
            return nil
        }
    }
}

extension Array where Element == URLQueryItem {
    static func from(_ params: PackageKeyParams) -> [URLQueryItem] {
        var out = [URLQueryItem]()
        
        if let platform = params.platform {
            out.append(URLQueryItem(name: "platform", value: platform))
        }
        
        if let arch = params.arch {
            out.append(URLQueryItem(name: "arch", value: arch))
        }
        
        if let version = params.version {
            out.append(URLQueryItem(name: "version", value: version))
        }
        
        if let channel = params.channel {
            out.append(URLQueryItem(name: "channel", value: channel))
        }
        
        return out
    }
}

enum PackageKeyError: Error {
    case invalidURL(String)
}

class PackageKey: Equatable, Hashable, CustomDebugStringConvertible {
    let repositoryURL: URL
    let id: String
    let params: PackageKeyParams?

    var debugDescription: String {
        "URL: \(repositoryURL), id: \(id), params: \(String(describing: params))"
    }
    
    init(repositoryURL: URL, id: String, params: PackageKeyParams? = nil) {
        self.repositoryURL = repositoryURL
        self.id = id
        self.params = params
    }
    
    static func from(url: URL) throws -> PackageKey {
        guard let id = url.pathComponents.last else {
            fatalError("this is impossible")
        }
        
        var newUrl = url.deletingLastPathComponent()
        
        if let end = newUrl.pathComponents.last, end != "packages" {
            throw PackageKeyError.invalidURL(url.absoluteString)
        }
        
        newUrl = newUrl.deletingLastPathComponent()
        
        var components = URLComponents(url: newUrl, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = PackageKeyParams(queryItems: queryItems)
        
        components.fragment = nil
        components.query = nil
        
        let repoURL = components.url!
        
        return PackageKey(repositoryURL: repoURL, id: id, params: params)
    }
    
    static func from(urlString: String) throws -> PackageKey {
        guard let url = URL(string: urlString) else {
            throw PackageKeyError.invalidURL(urlString)
        }
        
        return try PackageKey.from(url: url)
    }
    
    static func == (lhs: PackageKey, rhs: PackageKey) -> Bool {
        lhs.repositoryURL == rhs.repositoryURL
            && lhs.id == rhs.id
            && lhs.params == rhs.params
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(repositoryURL)
        hasher.combine(id)
        hasher.combine(params)
    }
    
    func toString() -> String {
        var urlBuilder = URLComponents(url: repositoryURL
            .appendingPathComponent("packages")
            .appendingPathComponent(id), resolvingAgainstBaseURL: false)!

        urlBuilder.queryItems = params.map { [URLQueryItem].from($0) }
        return urlBuilder.url!.absoluteString
    }
}

// TODO: think more
class MacOSPackageStore {}

//class Package {}

struct RepoRecord {
    let channel: String?
}

struct TransactionType {}

enum PackageActionType: UInt8 {
    case install = 0
    case uninstall = 1
}

extension PackageActionType {
    static func from(int value: UInt32) -> PackageActionType {
        if value == 0 {
            return .install
        } else {
            return .uninstall
        }
    }
    static func from(string value: String) -> PackageActionType {
        if value == "install" {
            return .install
        } else {
            return .uninstall
        }
    }
}


extension Descriptor {
    func firstRelease() -> Release? {
        self.release.first(where: {
            $0.target.contains(where: {
                $0.platform == "macos"
            })
        })
    }
    
    func firstVersion() -> String? {
        self.firstRelease()?.version
    }

    public var nativeName: String {
        for code in derivedLocales(Strings.languageCode) {
            if let name = self.name[code] {
                return name
            }
        }
        
        return self.name["en"] ?? ""
    }
}

extension Target {
    func macOSPackage() -> MacOSPackage? {
        guard let payload = self.payload else { return nil }
        
        switch payload {
        case let .macOSPackage(v):
            return v
        default:
            return nil
        }
    }
}

extension PackageStatus {
    var description: String {
        switch self {
        case .notInstalled:
            return Strings.notInstalled
        case .upToDate:
            return Strings.noUpdatesTitle
        case .requiresUpdate:
            return Strings.updateAvailable
        case .errorNoPackage:
            return Strings.errorUnknownPackage
        case .errorNoPayloadFound:
            return Strings.errorNoInstaller
        case .errorWrongPayloadType:
            return Strings.errorNoInstaller
        case .errorParsingVersion:
            return Strings.errorInvalidVersion
        case .errorCriteriaUnmet:
            return Strings.errorUnknownPackage
        case .errorUnknownStatus:
            return Strings.error
        }
    }
}

extension Release {
    public var nativeVersion: String {
        // Try to make this at least a _bit_ efficient
        if self.version.hasSuffix("Z") {
            return self.version.iso8601?.localeString ?? self.version
        }
        
        return self.version
    }
}

fileprivate let iso8601fmt: DateFormatter = {
    let iso8601fmt = DateFormatter()
    iso8601fmt.calendar = Calendar(identifier: .iso8601)
    iso8601fmt.locale = Locale(identifier: "en_US_POSIX")
    iso8601fmt.timeZone = TimeZone(secondsFromGMT: 0)
    iso8601fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return iso8601fmt
}()

fileprivate let localeFmt: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateStyle = .short
    fmt.timeStyle = .short
    return fmt
}()

extension Date {
    public var iso8601: String {
        return iso8601fmt.string(from: self)
    }
    
    public var localeString: String {
        return localeFmt.string(from: self)
    }
}

extension String {
    public var iso8601: Date? {
        return iso8601fmt.date(from: self)
    }
}
