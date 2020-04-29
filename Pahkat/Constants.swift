import Foundation

enum PahkatAppleEvent: UInt32 {
    static let classID: UInt32 = 0x504B4854 // "PHKT"
    case update = 0x504B5430 // "PKT0"
    case restartApp = 0x504B5431 // "PKT1"
    
    var stringValue: String {
        switch self {
        case .update:
            return "update"
        case .restartApp:
            return "restartApp"
        }
    }
}
