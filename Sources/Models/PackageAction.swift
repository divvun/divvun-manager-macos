import Foundation

struct PackageAction: Equatable, Hashable {
    let key: PackageKey
    let action: PackageActionType
    let target: SystemTarget

    static func from(_ protobuf: Pahkat_PackageAction) throws -> Self {
        let packageKey = try PackageKey.from(urlString: protobuf.id)
        let actionType = PackageActionType.from(int: protobuf.action)
        let target = SystemTarget.from(int: protobuf.target)

        return PackageAction(key: packageKey,
                             action: actionType,
                             target: target)
    }
}
