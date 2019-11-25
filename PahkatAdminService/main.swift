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
import PahkatClient

let kAuthorizationRightKeyClass = "class"
let kAuthorizationRightKeyGroup = "group"
let kAuthorizationRightKeyRule = "rule"
let kAuthorizationRightKeyTimeout = "timeout"
let kAuthorizationRightKeyVersion = "version"
let kAuthorizationFailedExitCode = NSNumber(value: 503340)

struct TransactionContainer {
    let transaction: PackageTransaction<InstallerTarget>
    var isCancelled: Bool
    
    init(_ transaction: PackageTransaction<InstallerTarget>) {
        self.transaction = transaction
        isCancelled = false
    }
    
    mutating func cancel() {
        self.isCancelled = true
    }
}

class PahkatAdminService: NSObject, NSXPCListenerDelegate, PahkatAdminProtocol {
    private let bag = DisposeBag()
    
    private var clientCache = [String: MacOSPackageStore]()
    private var txCount: UInt32 = 0
    private var txCache = [UInt32: TransactionContainer]()
    private let jsonEncoder = JSONEncoder()
    
    func xpcServiceVersion(withReply callback: @escaping (String) -> ()) {
        let v = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        callback(v)
    }
    
    private func client(for configPath: String) -> MacOSPackageStore? {
        var client: MacOSPackageStore? = nil
        
        if let maybeClient = self.clientCache[configPath] {
            client = maybeClient
        } else if let maybeClient = try? MacOSPackageStore.load(path: configPath) {
            self.clientCache[configPath] = maybeClient
            client = maybeClient
        }
        
        return client
    }
    
    func set(cachePath: String, for configPath: String) {
        guard let client = self.client(for: configPath) else { return }
        try! client.config().setCacheBase(path: cachePath)
    }
    
    func set(channel: String, for configPath: String) {
        guard let client = self.client(for: configPath) else { return }
        if let channel = Repository.Channels.init(rawValue: channel) {
            // HACK: this only exists for selfupdate, should be cleaned up.
            do {
                try client.config().set(repos: [RepoRecord(url: client.config().repos()[0].url, channel: channel)])
                try client.refreshRepos()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func createAdminTransaction(
        actionsData: /* [TransactionAction] as JSON */ Data,
        storeConfigPath configPath: String,
        txIdCallback callback: @escaping (/* XPCCallbackResponse as JSON */ Data) -> ()
    ) {
        guard let client = self.client(for: configPath) else {
            let payload = XPCCallbackResponse<Empty>.error(XPCError(message: "Path could not be parsed: \(configPath)"))
            callback(try! jsonEncoder.encode(payload))
            return
        }
//
//        if let cachePath = cachePath {
//            client.config().set(cachePath: cachePath)
//        }
        
        let actions = try! JSONDecoder().decode(
            [TransactionAction<InstallerTarget>].self,
            from: actionsData)
        
        let tx: PackageTransaction<InstallerTarget>
        do {
             tx = try client.transaction(actions: actions)
        } catch {
            let payload = XPCCallbackResponse<UInt32>.error(XPCError.from(error: error))
            print(payload)
            callback(try! jsonEncoder.encode(payload))
            return
        }
        
        // This txCount is separate to the internal tx count of the transaction
        self.txCount += 1
        let txId = self.txCount
        self.txCache[txId] = TransactionContainer(tx)

        let payload = XPCCallbackResponse.success(txId)
        print(payload)
        
        callback(try! jsonEncoder.encode(payload))
    }
    
    private lazy var receiver: PahkatAdminReceiverProtocol = {
        return self.connections.last!.remoteObjectProxyWithErrorHandler({
            print($0)
        }) as! PahkatAdminReceiverProtocol
    }()
    
    func processTransaction(txId: UInt32) {
        guard let container = self.txCache[txId] else {
            print("No tx found with id \(txId)")
            return
        }
        
        container.transaction.process(delegate: self)
    }
    
    func cancelTransaction(txId: UInt32) {
        self.txCache[txId]?.cancel()
    }
    
    private let listener: NSXPCListener
    
    private var connections = [NSXPCConnection]()
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0
    
    override init() {
        do {
            Client.shared = try Client(dsn: "https://554b508acddd44e98c5b3dc70f8641c1@sentry.io/1357390")
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
        // TODO: add this back in, from: https://github.com/erikberglund/SwiftPrivilegedHelper/
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

extension PahkatAdminService: PackageTransactionDelegate {
    func isTransactionCancelled(_ id: UInt32) -> Bool {
        return self.txCache[id]?.isCancelled ?? false
    }
    
    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey) {
        let state = XPCTransactionState.installing(id: id, packageKey: packageKey)
        receiver.transactionDidProgress(id: id, state: try! jsonEncoder.encode(state))
    }
    
    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey) {
        let state = XPCTransactionState.uninstalling(id: id, packageKey: packageKey)
        receiver.transactionDidProgress(id: id, state: try! jsonEncoder.encode(state))
    }
    
    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
        let state: XPCTransactionState
        if let error = error {
            state = XPCTransactionState.error(id: id, error: XPCError.from(error: error))
        } else {
            state = XPCTransactionState.error(id: id, error: XPCError(message: Strings.errorDuringInstallation))
        }
        receiver.transactionDidProgress(id: id, state: try! jsonEncoder.encode(state))
    }

    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32) {
        // Cannot happen :)
    }

    func transactionDidComplete(_ id: UInt32) {
        let state = XPCTransactionState.complete(id: id)
        receiver.transactionDidProgress(id: id, state: try! jsonEncoder.encode(state))
    }
    
    func transactionDidCancel(_ id: UInt32) {
        let state = XPCTransactionState.cancel(id: id)
        receiver.transactionDidProgress(id: id, state: try! jsonEncoder.encode(state))
    }
}

print("Loading service version \(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)")
let service = PahkatAdminService()
service.run()
