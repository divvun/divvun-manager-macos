//
//  RPCService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-04-16.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation
import GRPC
import NIO
import RxSwift

enum TransactionEvent {
    case none
    case transactionStarted(actions: [ResolvedAction])
    case transactionComplete
    case transactionProgress(packageKey: PackageKey?, message: String?, current: UInt64, total: UInt64)
    case transactionError(packageKey: PackageKey?, error: String?)
    case downloadProgress(packageKey: PackageKey?, current: UInt64, total: UInt64)
    case downloadError(packageKey: PackageKey?, error: String?)
    case downloadComplete(packageKey: PackageKey?)
    case installStarted(packageKey: PackageKey?)
    case uninstallStarted(packageKey: PackageKey?)
}


enum PackageStatus: Int32 {
    case notInstalled = 0
    case upToDate = 1
    case requiresUpdate = 2
    
    case errorNoPackage = -1
    case errorNoPayloadFound = -2
    case errorWrongPayloadType = -3
    case errorParsingVersion = -4
    case errorCriteriaUnmet = -5
    
    case errorUnknownStatus = -2147483648 // min Int32
    
    var isError: Bool {
        return self.rawValue < 0
    }
}

protocol PahkatClient: class {
    func repoIndexes() -> Single<[LoadedRepository]>
    func status(packageKey: PackageKey) -> Single<(PackageStatus, SystemTarget)>
    func processTransaction(actions: [ResolvedAction]) -> (() -> Completable, Observable<TransactionEvent>)
}

class MockPahkatClient: PahkatClient {
    func repoIndexes() -> Single<[LoadedRepository]> {
        return Single.just([
            LoadedRepository.mock(id: "1"),
            LoadedRepository.mock(id: "2"),
            LoadedRepository.mock(id: "3")
        ])
    }

    func status(packageKey: PackageKey) -> Single<(PackageStatus, SystemTarget)> {
        return Single.just((.notInstalled, .system))
    }
    
    func processTransaction(actions: [ResolvedAction]) -> (() -> Completable, Observable<TransactionEvent>) {
        let completable = { Completable.empty() }
        
        var fakeEvents = [TransactionEvent]()
        
        fakeEvents.append(TransactionEvent.transactionStarted(actions: actions))
        
        actions.forEach { action in
            if action.actionType == .install {
                fakeEvents.append(.downloadProgress(packageKey: action.key, current: 0, total: 100))
                fakeEvents.append(.downloadProgress(packageKey: action.key, current: 33, total: 100))
                fakeEvents.append(.downloadProgress(packageKey: action.key, current: 66, total: 100))
            }
        }
        
        actions.forEach { action in
            if action.actionType == .install {
                fakeEvents.append(.downloadComplete(packageKey: action.key))
            }
        }
        
        actions.forEach { action in
            if action.actionType == .install {
                fakeEvents.append(.installStarted(packageKey: action.key))
            } else {
                fakeEvents.append(.uninstallStarted(packageKey: action.key))
            }
        }

        fakeEvents.append(.transactionComplete)
        
        let observable = Observable.from(fakeEvents)
        
        return (completable, observable)
    }
}

class PahkatClientImpl: PahkatClient {
    private let inner: Pahkat_PahkatClient
    
    public func repoIndexes() -> Single<[LoadedRepository]> {
        let req = Pahkat_RepositoryIndexesRequest()
        let res = self.inner.repositoryIndexes(req)
        
        return Single<[LoadedRepository]>.create { emitter in
            res.response.whenSuccess { value in
                do {
                    let repos = try value.repositories.map {
                        try LoadedRepository.from(protobuf: $0)
                    }
                    emitter(.success(repos))
                } catch let error {
                    emitter(.error(error))
                }
            }
            
            res.response.whenFailure {
                emitter(.error($0))
            }
            
            return Disposables.create()
        }
    }
    
    private func status(packageKey: PackageKey, target: SystemTarget) -> Single<(PackageStatus, SystemTarget)> {
        var req = Pahkat_StatusRequest()
        req.packageID = packageKey.toString()
        req.target = UInt32(target.rawValue)
        let res = self.inner.status(req)
        
        return Single<(PackageStatus, SystemTarget)>.create { emitter in
            res.response.whenSuccess { value in
                let status = PackageStatus(rawValue: value.value) ?? PackageStatus.errorUnknownStatus
                emitter(.success((status, target)))
            }
            
            res.response.whenFailure {
                emitter(.error($0))
            }
            
            return Disposables.create()
        }
    }
    
    public func status(packageKey: PackageKey) -> Single<(PackageStatus, SystemTarget)> {
        self.status(packageKey: packageKey, target: .user).catchError { _ in
            self.status(packageKey: packageKey, target: .system)
        }
    }
    
    public func processTransaction(actions: [ResolvedAction]) -> (() -> Completable, Observable<TransactionEvent>) {
        let subject = ReplaySubject<TransactionEvent>.createUnbounded()
        
        let responseCallback: (Pahkat_TransactionResponse) -> Void = { response in
            guard let value = response.value else {
                // TODO: maybe? An error? Maybe.
                return
            }
            
            let event: TransactionEvent
            
            switch value {
            case .transactionStarted(_):
                event = .transactionStarted(actions: actions)
            case .transactionComplete(_):
                event = .transactionComplete
            case let .transactionProgress(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                let message = res.message == "" ? nil : res.message

                event = .transactionProgress(
                    packageKey: packageKey,
                    message: message,
                    current: res.current,
                    total: res.total)
            case let .transactionError(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                let error = res.error == "" ? nil : res.error
                
                event = .transactionError(
                    packageKey: packageKey,
                    error: error
                )
            case let .downloadProgress(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .downloadProgress(
                    packageKey: packageKey,
                    current: res.current,
                    total: res.total)
            case let .downloadError(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                let error = res.error == "" ? nil : res.error
                event = .downloadError(packageKey: packageKey, error: error)
            case let .downloadComplete(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .downloadComplete(packageKey: packageKey)
            case let .installStarted(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .installStarted(packageKey: packageKey)
            case let .uninstallStarted(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .uninstallStarted(packageKey: packageKey)
            
            }
            
            subject.onNext(event)
        }
        
        let sender = self.inner.processTransaction(handler: responseCallback)
        
        var req = Pahkat_TransactionRequest()
        // FIXME: do stuff
//        var transaction = Pahkat_TransactionRequest.Transaction()
//        transaction.actions = actions.map { action in
//            var a = Pahkat_PackageAction()
//            a.id = action.key.toString()
//            a.action = UInt32(action.action.rawValue)
//            a.target = UInt32(action.target.rawValue)
//            return a
//        }
//        req.transaction = transaction
        
        let _ = sender.sendMessage(req)
        
        let cancelCallback: () -> Completable = {
            var req = Pahkat_TransactionRequest()
            req.cancel = Pahkat_TransactionRequest.Cancel()
            let response = sender.sendMessage(req)
            
            return Completable.create { emitter in
                response.whenSuccess({ emitter(.completed) })
                response.whenFailure({ emitter(.error($0)) })
                
                return Disposables.create {}
            }
        }
        
        return (
            cancelCallback,
            subject.asObservable()
        )
    }
    
    init(unixSocketPath path: URL) {
        // TODO: 1.
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let conn = ClientConnection(
            configuration: .init(target: .unixDomainSocket(path.path),
                                 eventLoopGroup: group))
        let client = Pahkat_PahkatClient(channel: conn)
        
        inner = client
    }
}


