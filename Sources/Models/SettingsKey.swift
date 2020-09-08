import Foundation

enum SettingsKey: String, UserSettingsJSON {
    static let suiteName = "no.divvun.Pahkat"
    
    case interfaceLanguage = "AppleLanguages"
    case repositories = "no.divvun.Pahkat.repositories"
    case nextUpdateCheck = "no.divvun.Pahkat.nextUpdateCheck"
    case updateCheckInterval = "no.divvun.Pahkat.updateCheckInterval"
    
    var requiresJSON: Bool {
        switch self {
        case .interfaceLanguage, .nextUpdateCheck:
            return false
        case .repositories, .updateCheckInterval:
            return true
        }
    }
}
