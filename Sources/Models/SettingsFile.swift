import Foundation
import RxSwift


struct SettingsFile: Codable, ConfigFile {
    typealias Key = Keys
    
    private var language: String? = nil
    private var selectedRepository: URL? = nil
    
    enum Keys: String, CodingKey {
        case language
        case selectedRepository
    }
    
    func get(key: Keys) -> Any? {
        switch key {
        case .language:
            return language
        case .selectedRepository:
            return selectedRepository
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
        case .selectedRepository:
            if let value = value {
                if let string = value as? String, let url = URL(string: string) {
                    self.selectedRepository = url
                } else if let url = value as? URL {
                    self.selectedRepository = url
                }
            } else {
                self.selectedRepository = nil
            }
        }
    }
}

class Settings: Config<SettingsFile> {
    var language: Observable<String?> {
        self.observe(key: .language)
    }
    
    var selectedRepository: Observable<URL?> {
        self.observe(key: .selectedRepository)
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
