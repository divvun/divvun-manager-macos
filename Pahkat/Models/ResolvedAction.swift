import Foundation

struct ResolvedAction {
    let action: PackageAction
    let hasAction: Bool
    let name: [String: String]
    let version: String
}

extension ResolvedAction {
    var actionType: PackageActionType {
        action.action
    }

    var key: PackageKey {
        action.key
    }
}
