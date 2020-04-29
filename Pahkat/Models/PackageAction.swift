import Foundation

struct PackageAction: Equatable, Hashable {
    let key: PackageKey
    let action: PackageActionType
    let target: SystemTarget

    static func from(_ action: Pahkat_PackageAction) -> Self {
        let packageKey = PackageKey(repositoryURL: URL(string: "TODO ???")!, id: action.id) // TODO: where to get URL?
        let actionType = PackageActionType(rawValue: UInt8(action.action))
        let target = SystemTarget(rawValue: UInt8(action.target))
        return PackageAction(key: packageKey,
                             action: actionType ?? PackageActionType.install,
                             target: target ?? SystemTarget.user)
    }
}
