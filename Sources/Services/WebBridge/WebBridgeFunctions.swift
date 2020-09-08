import Cocoa
import RxSwift
import RxBlocking

class WebBridgeFunctions {
    private let repo: LoadedRepository
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    init(repo: LoadedRepository) {
        self.repo = repo
    }

    func process(request: WebBridgeRequest) -> Single<Data> {
        switch request.method {
        case "env":
            return env(request.args)
        case "string":
            return string(request.args)
        case "packages":
            return packages(request.args)
        case "status":
            return status(request.args)
        case "transaction":
            return transaction(request.args)
        default:
            break
        }

        return Single.error(ErrorResponse(error: "Unhandled method: \(request.method)"))
    }

    private func env(_ args: [JSONValue]) -> Single<Data> {
        // Returns useful environment variables
        return jsonEncoder.encodeAsync([
            "platform": "macos",
            "locale": "TODO",
        ])
    }

    private func string(_ args: [JSONValue]) -> Single<Data> {
        // No strings for now
        guard let key = args.first?.string else {
            return Single.error(ErrorResponse(error: "String request requires a single string argument"))
        }

        return Single.error(ErrorResponse(error: "No string found for key '\(key)'"))
    }

    private func status(_ args: [JSONValue]) -> Single<Data> {
        // varargs of PackageKey is assumed, return a map keyed by package key with status as int
        let keys = args.compactMap { $0.string }
            .compactMap { arg -> PackageKey? in
                return try? PackageKey.from(urlString: arg)
            }

        let keyObs: Observable<PackageKey> = Observable.from(keys)
        return keyObs.flatMap { key -> Single<(PackageKey, (PackageStatus, SystemTarget))> in
            AppContext.packageStore.status(packageKey: key).map { (key, $0) }
        }.toArray().map { array in
            var map = [String: JSONValue]()

            for (key, (status, target)) in array {
                map[key.toString()] = JSONValue.object([
                    "status": .number(Double(status.rawValue)),
                    "target": .string(target.rawValue)
                ])
            }

            return try self.jsonEncoder.encode(map)
        }
    }

    private func transaction(_ args: [JSONValue]) -> Single<Data> {
        // Args should be in the form of { key: PackageKey, action: "install"|"uninstall", target: "system"|"user" }
        var actions = [PackageAction]()

        for arg in args {
            guard let obj = arg.object else { continue }
            guard let key = obj["key"]?.string, let packageKey = try? PackageKey.from(urlString: key) else {
                continue
            }
            guard let action = obj["action"]?.string else { continue }
            guard let target = obj["target"]?.string else { continue }

            actions.append(PackageAction(key: packageKey,
                                         action: PackageActionType.from(string: action),
                                         target: SystemTarget.from(string: target)))
        }

        let packageNames = actions.map { (action) -> String in
            let descriptor = repo.descriptors[action.key.id]
            return descriptor?.nativeName ?? action.key.id
        }

        let alert = NSAlert()
        alert.addButton(withTitle: Strings.install)
        alert.addButton(withTitle: Strings.cancel)
        let names = packageNames.joined(separator: "\n - ")
        alert.messageText = "Package Transaction"
        alert.informativeText = "The following items are requested for installation:\n - \(names)\n\nDo you wish to continue?"

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            AppContext.startTransaction(actions: actions)
            return Single.just(try! jsonEncoder.encode(true))
        }

        return Single.just(try! jsonEncoder.encode(false))
    }

    private func packages(_ args: [JSONValue]) -> Single<Data> {
        // Args == 1 && first arg is PackageQuery
        if args.count >= 1 {
            let rawJson = try! jsonEncoder.encode(args[0])

            if let query = try? jsonDecoder.decode(PackageQuery.self, from: rawJson) {
                return AppContext.packageStore.resolvePackageQuery(query: query)
            }
        }

        // Args == 0? Return all packages

        print("packages: \(args)")

        var map = [String: Descriptor]()

        for descriptor in repo.descriptors.values {
            let key = repo.packageKey(for: descriptor)
            map[key.toString()] = descriptor
        }

        print("We done")

        return jsonEncoder.encodeAsync(map)
    }
}

extension JSONEncoder {
    func encodeAsync<T: Encodable>(_ input: T) -> Single<Data> {
        do {
            return Single.just(try encode(input))
        } catch let error {
            return Single.error(error)
        }
    }
}
