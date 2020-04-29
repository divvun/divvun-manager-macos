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

    static func from(_ protobuf: Pahkat_ResolvedAction) -> Self {
        let packageAction = PackageAction.from(protobuf.action)
        return ResolvedAction(action: packageAction, hasAction: protobuf.hasAction, name: protobuf.name, version: protobuf.version)
    }
}
