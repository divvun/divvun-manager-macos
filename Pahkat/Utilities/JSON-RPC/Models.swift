//
//  Models.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-16.
//  Copyright © 2018 Divvun. All rights reserved.
//

import RxSwift

class BufferedStringSubprocess {
    private let task = Process()
    
    private let stdin = Pipe()
    private let stdout = Pipe()
    private let stderr = Pipe()
    
    private func handler(_ output: ((String) -> ())?, for pipe: Pipe) {
        guard let output = output else {
            pipe.fileHandleForReading.readabilityHandler = nil
            return
        }
        
        var outputBuf = ""
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            guard let string = String(data: handle.availableData, encoding: .utf8) else {
                print("bad dartar")
                return
            }
//            print(string)
            outputBuf += string
            
            if !outputBuf.contains("\n") {
                return
            }
            
            var lines = outputBuf.components(separatedBy: "\n")
            
            if lines.count > 1 {
                outputBuf = lines.popLast()!
                lines.forEach(output)
            }
        }
    }
    
    var standardOutput: ((String) -> ())? {
        didSet {
            handler(standardOutput, for: stdout)
        }
    }
    
    var standardError: ((String) -> ())? {
        didSet {
            handler(standardError, for: stderr)
        }
    }
    
    var onComplete: (() -> ())?
    
    init(_ launchPath: String, arguments: [String], environment: [String: String]? = nil, qos: QualityOfService? = nil) {
        task.standardInput = stdin
        task.standardOutput = stdout
        task.standardError = stderr
        
        task.launchPath = launchPath
        task.arguments = arguments
        
        if let environment = environment {
            task.environment = environment
        }
        
        if let qos = qos {
            task.qualityOfService = qos
        }
        
        task.terminationHandler = { [weak self] _ in
            guard let `self` = self else { return }
            
            print("Exit code (\(self.task.launchPath!)): \(self.exitCode)")
            
            if self.exitCode == 0 {
                self.onComplete?()
            }
            
            // Avoids memory leaks.
            self.standardOutput = nil
            self.standardError = nil
            self.onComplete = nil
        }
    }
    
    func write(string: String, withNewline: Bool = true) {
        let handle = stdin.fileHandleForWriting
            
        handle.write(string.data(using: .utf8)!)
        
        if withNewline {
            handle.write("\n".data(using: .utf8)!)
        }
    }
    
    deinit {
        task.terminate()
        
        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        
        self.standardOutput = nil
        self.standardError = nil
        self.onComplete = nil
    }
    
    var currentDirectoryPath: String {
        get { return task.currentDirectoryPath }
        set { task.currentDirectoryPath = newValue }
    }
    
    var exitCode: Int32 {
        return task.terminationStatus
    }
    
    var isRunning: Bool {
        return task.isRunning
    }
    
    func launch() {
        task.launch()
    }
    
    func terminate() {
        task.terminate()
    }
    
    func waitUntilExit() {
        task.waitUntilExit()
    }
}


protocol JSONRPCRequest {
    associatedtype Response: Decodable
    
    var method: String { get }
    var params: Any? { get }
}

protocol JSONRPCSubscriptionRequest {
    associatedtype Response: Decodable
    
    var method: String { get }
    var params: Any? { get }
    var callback: String { get }
    var unsubscribeMethod: String? { get }
    var completionFilter: (Response) -> Bool { get }
}

extension JSONRPCSubscriptionRequest {
    var completionFilter: (Response) -> Bool {
        return { _ in false }
    }
    
    var params: Any? { return nil }
    var unsubscribeMethod: String? { return nil }
}

extension JSONRPCRequest {
    var params: Any? {
        return nil
    }
}

private struct JSONRPCRawCallbackParams<R: Decodable>: Decodable {
    let result: R
    let subscription: Int
}

struct JSONRPCRawCallback<R: Decodable>: Decodable {
    let method: String
    var result: R { return params.result }
    var subscription: Int { return params.subscription }
    
    private let params: JSONRPCRawCallbackParams<R>
}

struct JSONRPCRawResponse<R: Decodable>: Decodable {
    let id: Int
    let error: JSONRPCError?
    let result: R?
}

struct JSONRPCError: Error, Codable {
    let code: Int
    let message: String
}

fileprivate struct JSONRPCRawSubscribeRequest {
    let method: String
    let params: Any?
}

extension JSONRPCRawSubscribeRequest: JSONRPCRequest {
    typealias Response = Int
}

fileprivate struct JSONRPCRawUnsubscribeRequest {
    let method: String
    let subscription: Int
}

extension JSONRPCRawUnsubscribeRequest: JSONRPCRequest {
    typealias Response = Bool
    
    var params: Any? { return [subscription] }
}

class JSONRPCClient {
    private let outputSubject = PublishSubject<Data>()
    private var currentId: UInt = 0
    private let jsonDecoder = JSONDecoder()
    
    let input = PublishSubject<Data>()
    var output: Observable<Data> {
        return outputSubject.asObserver()
    }
    
    private func generatePayload(id: UInt?, method: String, params: Any? = nil) throws -> Data {
        var structure: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method
        ]
        
        if let id = id {
            structure["id"] = id
        }
        
        if let params = params {
            structure["params"] = params
        }
        
        return try JSONSerialization.data(withJSONObject: structure, options: [])
    }
    
    
    func send<R: JSONRPCRequest>(request: R) throws -> Single<R.Response> {
        let id = currentId
        let payload = try generatePayload(id: id, method: request.method, params: request.params)
        currentId += 1
        
        return input
            .do(onSubscribed: { [weak self] in
                print("Sending payload: \(String(data: payload, encoding: .utf8)!)")
                self?.outputSubject.onNext(payload)
            })
            .flatMapLatest { [weak self] (data: Data) -> Observable<JSONRPCRawResponse<R.Response>> in
                guard let jsonDecoder = self?.jsonDecoder else {
                    return Observable.empty()
                }
                
                do {
                    let obj = try jsonDecoder.decode(JSONRPCRawResponse<R.Response>.self, from: data)
                    return Observable.just(obj)
                } catch {
                    print("Failed to decode: \(String(data: data, encoding: .utf8)!)")
                    return Observable.error(error)
                }
            }
            .filter {
                id == $0.id
            }
            .flatMapLatest { (response: JSONRPCRawResponse<R.Response>) -> Observable<R.Response> in
                if let error = response.error { return Observable.error(error) }
                guard let result = response.result else { return Observable.empty() }
                return Observable.just(result)
            }
            .take(1)
            .asSingle()
    }
    
    func send<R: JSONRPCRequest>(notification request: R) throws {
        let payload = try generatePayload(id: nil, method: request.method, params: request.params)
        outputSubject.onNext(payload)
    }
    
    func send<R: JSONRPCSubscriptionRequest>(subscription request: R) throws -> Observable<R.Response> {
        let initRequest = try self.send(request: JSONRPCRawSubscribeRequest(method: request.method, params: request.params))
        let observable = Observable.combineLatest(
            initRequest.asObservable(),
            input,
            resultSelector: { (subscription: Int, input: Data) in
                return (subscription, input)
            })
        
        var subscriptionId: Int? = nil
        
        return observable
            .flatMapLatest { [weak self] (subscription: Int, data: Data) -> Observable<JSONRPCRawCallback<R.Response>> in
                subscriptionId = subscription
                
                guard let jsonDecoder = self?.jsonDecoder else { return Observable.empty() }
                guard let obj = try? jsonDecoder.decode(JSONRPCRawCallback<R.Response>.self, from: data) else {
                    return Observable.empty()
                }
                if subscription != obj.subscription { return Observable.empty() }
                return Observable.just(obj)
            }
            .map { $0.result }
            .takeWhile({ !request.completionFilter($0) })
            .do(onCompleted: { [weak self] in
                guard let method = request.unsubscribeMethod else { return }
                guard let subscription = subscriptionId else { return }
                try? self?.send(notification: JSONRPCRawUnsubscribeRequest(method: method, subscription: subscription))
            })
    }
}

