//
//  WebBridgeService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-20.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import PahkatClient
import WebKit
import BTree

indirect enum Value: Codable {
    init(from decoder: Decoder) throws {
        let d = try decoder.singleValueContainer()
        
        if let value = try? d.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? d.decode(Double.self) {
            self = .number(value)
        } else if let value = try? d.decode(String.self) {
            self = .string(value)
        } else if let value = try? d.decode([Value].self) {
            self = .array(value)
        } else if let value = try? d.decode([String: Value].self) {
            self = .object(value)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try c.encodeNil()
        case .boolean(let v):
            try c.encode(v)
        case .number(let v):
            try c.encode(v)
        case .string(let v):
            try c.encode(v)
        case .array(let v):
            try c.encode(v)
        case .object(let v):
            try c.encode(v)
        }
    }
    
    case null
    case boolean(Bool)
    case number(Double)
    case string(String)
    case array([Value])
    case object([String: Value])
    
    var string: String? {
        switch self {
        case .string(let v):
            return v
        default:
            return nil
        }
    }
}

struct WebBridgeRequest: Codable {
    let id: UInt
    let method: String
    let args: [Value]
}

struct LanguageResponse: Codable {
    let languageName: String
    let packages: [PackageKey: Package]
}

struct ErrorResponse: Codable {
    let error: String
}

class WebBridgeService: NSObject, WKScriptMessageHandler {
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private lazy var defaultResponse = { try! jsonEncoder.encode("{}") }()
    
    private weak var webView: WKWebView?
    
    init(webView: WKWebView) {
        self.webView = webView
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
        
        var responseData: Data = defaultResponse
        
        do {
            switch request.method {
            case "searchByLanguage":
                responseData = try searchByLanguage(args: request.args)
            case "install":
                break
            case "uninstall":
                break
            case "string":
                break
            case "packages":
                break
            default:
                log.warning("Invalid method: \(request.method)")
            }
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
        
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    func searchByLanguage(args: [Value]) throws -> Data {
        guard let query = args.first?.string else {
            return try jsonEncoder.encode(ErrorResponse(error: "No query provided"))
        }
        
        let repos = try AppContext.client.repoIndexes()
        
        // TODO search
        
        let response = LanguageResponse(languageName: "", packages: [:])
        return try jsonEncoder.encode(response)
    }
    
    func install(packageKeys: [PackageKey]) {
        
    }
    
    func uninstall(packageKeys: [PackageKey]) {
        
    }
    
    func string(key: String, args: [String] = []) {
        
    }
    
    func packages(packageKeys: [PackageKey]) -> [Package] {
        let repos = try! AppContext.client.repoIndexes()
//        packageKeys.map { $0. }
        return []
    }
}
