import Foundation

enum SettingsKey: String, UserSettingsJSON {
    static let suiteName = "no.divvun.Manager"
    
    case interfaceLanguage = "AppleLanguages"
    case repositories = "no.divvun.Manager.repositories"
    case nextUpdateCheck = "no.divvun.Manager.nextUpdateCheck"
    case updateCheckInterval = "no.divvun.Manager.updateCheckInterval"
    
    var requiresJSON: Bool {
        switch self {
        case .interfaceLanguage, .nextUpdateCheck:
            return false
        case .repositories, .updateCheckInterval:
            return true
        }
    }
}
