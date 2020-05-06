//
//  WebBridgeService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-20.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import WebKit

struct LanguageResponse: Encodable {
    let languageName: String
    var packages: [String: Descriptor]
    var size: String
    var installedSize: String
    var groupStatus: String
    var statuses: [String: String]
}

protocol WebBridgeViewable: class {
    func handle(error: Error)
}

class WebBridgeService: NSObject, WKScriptMessageHandler {
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private lazy var defaultResponse = { try! jsonEncoder.encode("{}") }()
    
    private weak var webView: WKWebView?
    private weak var view: WebBridgeViewable?
    
    init(webView: WKWebView, view: WebBridgeViewable) {
        self.webView = webView
        self.view = view
    }
    
    func start(url: URL) {
        guard let webView = webView else { return }
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.add(self, name: "pahkat")
        webView.load(URLRequest(url: url))
    }
    
    private func process(request: WebBridgeRequest) throws -> Data {
        switch request.method {
        case "env":
            // responseData = try env(request.args)
            break
        case "string":
            break
        case "packages":
            break
        case "status":
            break
        case "transaction":
            break
        default:
            break
        }

        throw ErrorResponse(error: "Unhandled method: \(request.method)")
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage)
    {
        if message.name != "pahkat" {
            return
        }
        
        guard let p = message.body as? String, let payload = p.data(using: .utf8) else {
            return
        }
        
        let request: WebBridgeRequest
        do {
            request = try jsonDecoder.decode(WebBridgeRequest.self, from: payload)
        } catch {
            log.error(error)
            return
        }
        
        print("Request: \(request)")
        
        var responseData: Data = defaultResponse
        
        do {
            responseData = try process(request: request)
        } catch let error as ErrorResponse {
            responseData = try! jsonEncoder.encode(error)
        } catch {
            do {
                responseData = try jsonEncoder.encode(ErrorResponse(error: String(describing: error)))
            } catch {
                responseData = try! jsonEncoder.encode(ErrorResponse(error: "An unhandled error occurred"))
            }
        }
        
        let response = String(data: responseData, encoding: .utf8)!
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let js = "window.pahkatResponders[\"callback-\(request.id)\"](\"\(response)\")"
        print(response)
        
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
//    func searchByLanguage(args: [Value]) throws -> Data {
//        guard let query = args.first?.string else {
//            return try jsonEncoder.encode(ErrorResponse(error: "No query provided"))
//        }
//
//        let repos = try AppContext.client.repoIndexesWithStatuses()
//        var results: [String: LanguageResponse] = [:]
//
//        var statuses = [String: PackageInstallStatus]()
//
//        repos.forEach { repo in
//            let langResults = repo.packages.values
//                .filter { pkg in pkg.languages.first?.starts(with: query) ?? false }
//                .map { pkg in (pkg.languages.first!, repo.absoluteKey(for: pkg), pkg) }
//
//            for result in langResults {
//                if results.index(forKey: result.0) == nil {
//                    let name: String
//                    if let iso639 = ISO639.get(tag: result.0) {
//                        name = iso639.autonymOrName
//                    } else {
//                        name = result.0
//                    }
//                    results[result.0] = LanguageResponse(
//                        languageName: name, packages: [:], size: "-", installedSize: "-", groupStatus: "unknown", statuses: [:])
//                }
//
//                guard let status = repo.status(for: result.1)?.status else {
//                    continue
//                }
//
//                if status.isError() {
//                    continue
//                }
//
//                statuses[result.1.rawValue] = status
//                results[result.0]?.packages[result.1.rawValue] = result.2
//            }
//        }
//
//        // Non-linguistic content not allowed
//        results.removeValue(forKey: "zxx")
//
//        // Calculate sizes
//        let byteCountFormatter = ByteCountFormatter()
//        results = results.mapValues { value in
//            var response = value
//            let (size, installedSize) = value.packages
//                .filter { $0.1.macOSInstaller != nil }
//                .reduce((Int64(0), Int64(0)), { acc, cur in
//                    let installer = cur.value.macOSInstaller!
//                    let size: Int64
//                    if let status = statuses[cur.key] {
//                        switch status {
//                        case .notInstalled, .requiresUpdate:
//                            size = Int64(installer.size)
//                        default:
//                            size = 0
//                        }
//                    } else {
//                        size = 0
//                    }
//
//                    return (acc.0 + size, acc.1 + Int64(installer.installedSize))
//                })
//
//            let statusSet = Set(value.packages.keys.compactMap { statuses[$0] })
//            let groupStatus: PackageInstallStatus
//
//            if statusSet.contains(.requiresUpdate) {
//                groupStatus = .requiresUpdate
//            } else if statusSet.contains(.notInstalled) {
//                if statusSet.count == 1 {
//                    groupStatus = .notInstalled
//                } else {
//                    groupStatus = .requiresUpdate
//                }
//            } else {
//                groupStatus = .upToDate
//            }
//
//            response.size = byteCountFormatter.string(fromByteCount: Int64(size))
//            response.installedSize = byteCountFormatter.string(fromByteCount: Int64(installedSize))
//            response.groupStatus = groupStatus.stringValue!
//
//            var localStatuses = [String: String]()
//            for k in response.packages.keys {
//                localStatuses[k] = statuses[k]?.stringValue!
//            }
//            response.statuses = localStatuses
//            return response
//        }
//
//        return try jsonEncoder.encode(results)
//    }
//    
//    func install(args: [Value]) throws {
//        let repos = try AppContext.client.repoIndexesWithStatuses()
//        let packageKeys = args.compactMap { $0.string }
//            .compactMap { URL(string: $0) }
//            .map { PackageKey(from: $0) }
//        
//        let alert = NSAlert()
//        alert.addButton(withTitle: Strings.install)
//        alert.addButton(withTitle: Strings.cancel)
//        let names = packageKeys.map { $0.rawValue }.joined(separator: "\n - ")
//        alert.messageText = "Install Packages"
//        alert.informativeText = "The following items are requested for installation:\n - \(names)\n\nDo you wish to continue?"
//       
//        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
//            let actions = packageKeys.map { TransactionAction.install($0, target: InstallerTarget.system) }
//            _ = PackageStoreProxy.instance.transaction(actions: actions).subscribe(
//                onSuccess: { [weak view] tx in view?.showDownloadView(transaction: tx, repos: repos) },
//                onError: { [weak view] error in view?.handle(error: error) })
//        }
//    }
//    
//    func uninstall(packageKeys: [PackageKey]) {
//        
//    }
//    
//    func string(key: String, args: [String] = []) {
//        
//    }
//    
//    func packages(packageKeys: [PackageKey]) -> [Package] {
//        let repos = try! AppContext.client.repoIndexesWithStatuses()
////        packageKeys.map { $0. }
//        return []
//    }
}
