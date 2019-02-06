//
//  APIService+Extensions.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-20.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

extension Package.Installer {
    var size: Int64 {
        switch self {
        case let .windowsInstaller(installer):
            return Int64(installer.size)
        case let .macOsInstaller(installer):
            return Int64(installer.size)
        case let .tarballInstaller(installer):
            return Int64(installer.size)
        }
    }
}

extension Package: Comparable {
    public static func <(lhs: Package, rhs: Package) -> Bool {
        switch lhs.nativeName.localizedCaseInsensitiveCompare(rhs.nativeName) {
        case .orderedAscending:
            return true
        default:
            return false
        }
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
    var iso8601: String {
        return iso8601fmt.string(from: self)
    }
    
    var localeString: String {
        return localeFmt.string(from: self)
    }
}

extension String {
    var iso8601: Date? {
        return iso8601fmt.date(from: self)
    }
}

extension Package {
    var nativeVersion: String {
        // Try to make this at least a _bit_ efficient
        if self.version.hasSuffix("Z") {
            return self.version.iso8601?.localeString ?? self.version
        }
        
        return self.version
    }
    
    var nativeName: String {
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
            if let name = self.name[code] {
                return name
            }
        }
        
        return self.name["en"] ?? ""
    }
    
    var nativeInstaller: MacOsInstaller? {
        switch installer {
        case .macOsInstaller(let x):
            return x
        default:
            return nil
        }
    }
}

extension Repository {
    var nativeName: String {
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
            if let name = self.name[code] {
                return name
            }
        }
        
        return self.name["en"] ?? ""
    }
    
    func nativeCategory(for key: String) -> String {
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
            guard let map = self.categories[code] else {
                continue
            }
            
            return map[key] ?? key
        }
        
        return key
    }
}
