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

extension Package {
    var nativeName: String {
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
            if let name = self.name[code] {
                return name
            }
        }
        
        return self.name["en"] ?? ""
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
