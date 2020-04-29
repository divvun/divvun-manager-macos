import Foundation

struct PackageAction: Equatable, Hashable {
    let key: PackageKey
    let action: PackageActionType
    let target: SystemTarget

    static func from(_ protobuf: Pahkat_PackageAction) -> Self {
        let packageKey = PackageKey(repositoryURL: URL(string: "TODO ???")!, id: protobuf.id) // TODO: where to get URL?
        let actionType = PackageActionType(rawValue: UInt8(protobuf.action))
        let target = SystemTarget(rawValue: UInt8(protobuf.target))
        return PackageAction(key: packageKey,
                             action: actionType ?? PackageActionType.install,
                             target: target ?? SystemTarget.user)
    }
}
