//
//  PahkatAdminReceiver.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation
import ServiceManagement
import RxSwift
import PahkatClient

@objc protocol PahkatAdminReceiverProtocol {
    func transactionDidProgress(id: UInt32, state: Data)
}

struct LaunchServiceError: Error {
    let message: String
}

// This is the receiver object that is used by the non-privileged app to access admin functionality
class PahkatAdminReceiver: PahkatAdminReceiverProtocol {
    static public let instance = PahkatAdminReceiver()
    static private let subject: PublishSubject<XPCTransactionState> = {
        let x = PublishSubject<XPCTransactionState>()
        x.subscribe(onNext: { event in
            print(String(describing: event))
        })
        return x
    }()
    
    static func registerProxy(txId: UInt32) -> Observable<XPCTransactionState> {
        Self.subject.filter { $0.id == txId }
            .takeUntil(.inclusive, predicate: { $0.isComplete })
    }
    
    static func checkForAdminService() -> Completable {
        return Completable.create(subscribe: { emitter in
            let recv = PahkatAdminReceiver()

            return recv.isLaunchServiceInstalled
                .observeOn(MainScheduler.instance)
                .timeout(1.0, scheduler: MainScheduler.instance)
                .catchErrorJustReturn(false)
                .subscribe(onSuccess: { isInstalled in
                    if !isInstalled {
                        do {
                            _ = try recv.installLaunchService(errorCallback: { error in
                                emitter(.error(error))
                            })

                            emitter(.completed)
                        } catch  {
                            emitter(.error(error))
                            return
                        }
                    } else {
                        emitter(.completed)
                    }
                })
        })
    }
    
    func transactionDidProgress(id: UInt32, state: Data) {
        let xpcState: XPCTransactionState
        do {
            xpcState = try JSONDecoder().decode(XPCTransactionState.self, from: state)
        } catch {
            xpcState = .error(id: id, error: XPCError.from(error: error))
        }
        
        // This propagates the received admin-triggered event to the app
//        transactionSubject.onNext(xpcState)
        Self.subject.onNext(xpcState)
    }
    
    private let machServiceName: String = "no.divvun.PahkatAdminService"
    private var currentConnection: NSXPCConnection? = nil

    private var launchServicePath: URL {
        return Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LaunchServices")
            .appendingPathComponent(machServiceName)
    }
    
    var isLaunchServiceInstalled: Single<Bool> {
        // This loads the bundle from a Mach-O binary.
        guard let info = CFBundleCopyInfoDictionaryForURL(launchServicePath as CFURL) as? [String: Any] else {
            fatalError("Launch services bundle must be present")
        }
        
        guard let shortVersion = info["CFBundleShortVersionString"] as? String else {
            fatalError("Launch services bundle must contain CFBundleShortVersionString")
        }
        
        return Single<Bool>.create(subscribe: { emitter in
            self.service(errorCallback: { err in
                emitter(.success(false))
            }).xpcServiceVersion(withReply: { (v: String) -> () in
                emitter(.success(v == shortVersion))
            })
            
            return Disposables.create()
        })
    }
    
    private func connection() -> NSXPCConnection {
        if let connection = self.currentConnection {
            return connection
        }
        
        let connection = NSXPCConnection(machServiceName: self.machServiceName, options: .privileged)
        connection.exportedInterface = NSXPCInterface(with: PahkatAdminReceiverProtocol.self)
        connection.exportedObject = self
        
        let factoryInterface = NSXPCInterface(with: PahkatAdminProtocol.self)
        connection.remoteObjectInterface = factoryInterface
        connection.invalidationHandler = {
            self.currentConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.currentConnection = nil
            }
        }
        
        self.currentConnection = connection
        connection.resume()
        
        return connection
    }
    
    func service(errorCallback: @escaping (NSError) -> ()) -> PahkatAdminProtocol {
        guard let service = self.connection().remoteObjectProxyWithErrorHandler({ error in
            errorCallback(error as NSError)
        }) as? PahkatAdminProtocol else {
            fatalError("Service returned another protocol than expected")
        }
        
        return service
    }
    
    func installLaunchService(errorCallback: @escaping (NSError) -> ()) throws -> PahkatAdminProtocol {
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        
        var authRef: AuthorizationRef?
        let result = AuthorizationCreate(&authRights, nil, [.interactionAllowed, .extendRights, .preAuthorize], &authRef)
            
        if result != errAuthorizationSuccess {
            throw LaunchServiceError(message: String(describing: SecCopyErrorMessageString(result, nil)))
        }
        
        var cfError: Unmanaged<CFError>?
        SMJobBless(kSMDomainSystemLaunchd, machServiceName as CFString, authRef, &cfError)
        if let error = cfError?.takeRetainedValue() {
            print(String(describing: error as Error))
            throw LaunchServiceError(message: String(describing: error as Error))
        }
        
        self.currentConnection?.invalidate()
        self.currentConnection = nil
        
        return self.service(errorCallback: errorCallback)
    }
    
    private init() {}
}
