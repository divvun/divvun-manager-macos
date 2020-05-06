//
//  WebBridgeFunctions.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-05-06.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxBlocking

class WebBridgeFunctions {
    private let repo: LoadedRepository
    private let jsonEncoder = JSONEncoder()

    init(repo: LoadedRepository) {
        self.repo = repo
    }

    func process(request: WebBridgeRequest) throws -> Data {
        switch request.method {
        case "env":
            return try env(request.args)
        case "string":
            return try string(request.args)
        case "packages":
            return try packages(request.args)
        case "status":
            return try status(request.args)
        case "transaction":
            return try transaction(request.args)
        default:
            break
        }

        throw ErrorResponse(error: "Unhandled method: \(request.method)")
    }

    private func env(_ args: [JSONValue]) throws -> Data {
        // Returns useful environment variables
        return try jsonEncoder.encode([
            "platform": "macos"
        ])
    }

    private func string(_ args: [JSONValue]) throws -> Data {
        // No strings for now
        guard let key = args.first?.string else {
            throw ErrorResponse(error: "String request requires a single string argument")
        }

        throw ErrorResponse(error: "No string found for key '\(key)'")
    }

    private func status(_ args: [JSONValue]) throws -> Data {
        // varargs of PackageKey is assumed, return a map keyed by package key with status as int
        let requests = args.compactMap { $0.string }
            .compactMap { arg -> PackageKey? in
                return try? PackageKey.from(urlString: arg)
            }
            .map { ($0, AppContext.packageStore.status(packageKey: $0)) }
        

        // Terrible hack.
        var map = [String: JSONValue]()
        try requests.forEach { (key, single) in
            let (status, target) = try single.toBlocking(timeout: 5).single()

            map[key.toString()] = JSONValue.object([
                "status": .number(Double(status.rawValue)),
                "target": .string(target.rawValue)
            ])
        }
        return try jsonEncoder.encode(map)
    }

    private func transaction(_ args: [JSONValue]) throws -> Data {
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

        // TODO get package names properly

        let alert = NSAlert()
        alert.addButton(withTitle: Strings.install)
        alert.addButton(withTitle: Strings.cancel)
        let names = actions.map { $0.key.id }.joined(separator: "\n - ")
        alert.messageText = "Package Transaction"
        alert.informativeText = "The following items are requested for installation:\n - \(names)\n\nDo you wish to continue?"

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            AppContext.startTransaction(actions: actions)
            return try jsonEncoder.encode(true)
        }

        return try jsonEncoder.encode(false)
    }

    private func packages(_ args: [JSONValue]) throws -> Data {
        // Args == 0? Return all packages

        print("packages: \(args)")

        var map = [String: Descriptor]()

        for descriptor in repo.descriptors.values {
            let key = repo.packageKey(for: descriptor)
            map[key.toString()] = descriptor
        }

        print("We done")

        return try jsonEncoder.encode(map)
    }
}
