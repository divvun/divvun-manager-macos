import Foundation

struct ResolvedAction: Equatable {
    let action: PackageAction
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

    // TODO: make protocol ext? used on Descriptor too
    public var nativeName: String {
        for code in derivedLocales(Strings.languageCode) {
            if let name = self.name[code] {
                return name
            }
        }
        return self.name["en"] ?? ""
    }

    static func from(_ protobuf: Pahkat_ResolvedAction) throws -> Self {
        let packageAction = try PackageAction.from(protobuf.action)
        return ResolvedAction(action: packageAction, name: protobuf.name, version: protobuf.version)
    }
}
