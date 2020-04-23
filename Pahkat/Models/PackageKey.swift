//
//  PackageKey.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-04-15.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation

struct PackageKeyParams {
    
}

class PackageKey: Equatable, Hashable {
    let repositoryURL: URL
    let id: String
    let params: PackageKeyParams?
    
    init(repositoryURL: URL, id: String, params: PackageKeyParams? = nil) {
        self.repositoryURL = repositoryURL
        self.id = id
        self.params = params
    }
    
    static func from(urlString: String) throws -> Self {
        todo()
    }
    
    static func == (lhs: PackageKey, rhs: PackageKey) -> Bool {
        lhs.repositoryURL == rhs.repositoryURL
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(repositoryURL)
    }
    
    func toString() -> String {
        todo()
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
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
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
        default:
            todo()
            return "TODO"
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
