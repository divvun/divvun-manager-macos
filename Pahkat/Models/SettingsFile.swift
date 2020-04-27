import Foundation
import RxSwift


struct SettingsFile: Codable, ConfigFile {
    typealias Key = Keys
    
    private var language: String? = nil
    
    enum Keys: String, CodingKey {
        case language
    }
    
    func get(key: Keys) -> Any? {
        switch key {
        case .language:
            return language
        }
    }
    
    mutating func set(key: Keys, value: Any?) {
        switch key {
        case .language:
            if let value = value {
                if let string = value as? String {
                    self.language = string
                }
            } else {
                self.language = nil
            }
        }
    }
}

class Settings: Config<SettingsFile> {
    var language: Observable<String?> {
        self.observe(key: .language)
    }
    
    init() throws {
        let prefsPath = try FileManager.default
            .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("Preferences")
        
        let divvunInstallerPrefsPath = prefsPath.appendingPathComponent("Divvun Installer")
        try FileManager.default
            .createDirectory(at: divvunInstallerPrefsPath, withIntermediateDirectories: true, attributes: nil)
        
        let settingsFilePath = divvunInstallerPrefsPath.appendingPathComponent("settings.json")
        
        try super.init(settingsFilePath)
    }
}
