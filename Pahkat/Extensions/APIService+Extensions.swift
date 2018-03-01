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

extension Package {
    var nativeName: String {
        return self.name[Strings.languageCode ?? "en"] ?? ""
    }
}

extension Repository {
    var nativeName: String {
        return self.name[Strings.languageCode ?? "en"] ?? ""
    }
    
    func nativeCategory(for key: String) -> String {
        guard let map = self.categories[Strings.languageCode ?? "en"] else {
            return key
        }
        
        return map[key] ?? key
    }
}
