//
//  main.swift
//  PahkatAdminService
//
//  Created by Brendan Molloy on 2018-11-29.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import Sentry
import RxSwift

let kAuthorizationRightKeyClass = "class"
let kAuthorizationRightKeyGroup = "group"
let kAuthorizationRightKeyRule = "rule"
let kAuthorizationRightKeyTimeout = "timeout"
let kAuthorizationRightKeyVersion = "version"
let kAuthorizationFailedExitCode = NSNumber(value: 503340)

final class PahkatAdminClient : PahkatClient {
    override func transaction(of actions: [TransactionAction]) -> Single<PahkatTransactionType> {
        do {
            return Single.just(try PahkatTransaction(client: self, actions: actions))
        } catch {
            return Single.error(error)
        }
    }
}

class PahkatAdminService: NSObject, NSXPCListenerDelegate, PahkatAdminProtocol {
    let bag = DisposeBag()
    
    private var clientCache = [String: PahkatAdminClient]()
    private var txCount: UInt32 = 0
    private var txCache = [UInt32: PahkatTransactionType]()
    
    func xpcServiceVersion(withReply callback: @escaping (String) -> ()) {
        let v = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        callback(v)
    }
    
    // JSON on both sides.
    func transaction(of actionsJSON: Data, configPath: String, withReply callback: @escaping (Data) -> ()) {
        let client: PahkatAdminClient
        
        if let maybeClient = self.clientCache[configPath] {
            client = maybeClient
        } else if let maybeClient = PahkatAdminClient(configPath: configPath) {
            self.clientCache[configPath] = maybeClient
            client = maybeClient
        } else {
            let payload = ["error": "Path could not be parsed: \(configPath)"]
            callback(try! JSONEncoder().encode(payload))
            return
        }
        
        let actions = try! JSONDecoder().decode([TransactionAction].self, from: actionsJSON)
        
        client.transaction(of: actions)
            .subscribe(onSuccess: { tx in
                self.txCount += 1
                let txId = self.txCount
                self.txCache[txId] = tx
                
                let payload = ["success": AdminTransactionResponse(txId: txId, actions: tx.actions)]
                print(payload)
                callback(try! JSONEncoder().encode(payload))
            }, onError: { error in
                let payload = ["error": String(describing: error)]
                print(payload)
                callback(try! JSONEncoder().encode(payload))
            }).disposed(by: bag)
    }
    
    func processTransaction(txId: UInt32) {
        guard let tx = self.txCache[txId] else {
            print("No tx found with id \(txId)")
            return
        }
        
        let receiver = self.connections.last!.remoteObjectProxyWithErrorHandler({
            print($0)
        }) as! PahkatAdminReceiverProtocol
        
        let enc = JSONEncoder()
        tx.process(callback: { (error, event) in
            if let error = error {
                let payload = TransactionEvent(txId: txId, event: .error, error: String(describing: error))
                receiver.transactionEvent(data: try! enc.encode(payload))
            } else if let event = event {
                let payload = TransactionEvent(txId: txId, event: .package, packageEvent: event)
                let data = try! enc.encode(payload)
                receiver.transactionEvent(data: data)
            } else {
                let payload1 = TransactionEvent(txId: txId, event: .completed)
                let payload2 = TransactionEvent(txId: txId, event: .dispose)
                receiver.transactionEvent(data: try! enc.encode(payload1))
                receiver.transactionEvent(data: try! enc.encode(payload2))
            }
        })
    }
    
    private let listener: NSXPCListener
    
    private var connections = [NSXPCConnection]()
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0
    
    override init() {
        do {
            Client.shared = try Client(dsn: "https://85710416203c49ec87d9317948dad3c5@sentry.io/292199")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("\(error)")
            // Wrong DSN or KSCrash not installed
        }
        
        ProcessInfo.processInfo.disableAutomaticTermination("No")
        
        self.listener = NSXPCListener(machServiceName: "no.divvun.PahkatAdminService")
        super.init()
        self.listener.delegate = self
    }
    
    public func run() {
        self.listener.resume()
        
        // Keep the helper tool running until the variable shouldQuit is set to true.
        // The variable should be changed in the "listener(_ listener:shoudlAcceptNewConnection:)" function.
        
        while !self.shouldQuit {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: self.shouldQuitCheckInterval))
        }
//        RunLoop.current.run()
    }
    
    private func isValid(connection: NSXPCConnection) -> Bool {
        return true
    }
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        // Verify that the calling application is signed using the same code signing certificate as the helper
//        guard self.isValid(connection: connection) else {
//            return false
//        }
        
        // Set the protocol that the calling application conforms to.
        connection.remoteObjectInterface = NSXPCInterface(with: PahkatAdminReceiverProtocol.self)
        
        // Set the protocol that the helper conforms to.
        let factoryInterface = NSXPCInterface(with: PahkatAdminProtocol.self)
        connection.exportedInterface = factoryInterface
        connection.exportedObject = self
        
        // Set the invalidation handler to remove this connection when it's work is completed.
        connection.invalidationHandler = {
            if let connectionIndex = self.connections.firstIndex(of: connection) {
                self.connections.remove(at: connectionIndex)
            }
            
            if self.connections.isEmpty {
                self.shouldQuit = true
            }
        }
        
        self.connections.append(connection)
        connection.resume()
        
        return true
    }
}

print("Loading service version \(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)")
let service = PahkatAdminService()
service.run()
