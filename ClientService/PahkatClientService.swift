//
//  PahkatClientService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-11-25.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct PackageEvent: Codable {
    let packageId: AbsolutePackageKey
    let event: PackageEventType
}

enum PackageEventType: UInt32, Codable {
    case notStarted = 0
    case uninstalling = 1
    case installing = 2
    case completed = 3
    case error = 4
}

struct TransactionEvent: Codable {
    let txId: UInt32
    let event: TransactionEventType
    let packageEvent: PackageEvent?
    let error: String?
    
    init(txId: UInt32, event: TransactionEventType, packageEvent: PackageEvent? = nil, error: String? = nil) {
        self.txId = txId
        self.event = event
        self.packageEvent = packageEvent
        self.error = error
    }
}

enum TransactionEventType: UInt32, Codable {
    case package
    case completed
    case error
    case dispose
}

fileprivate var transactionIdCount = UInt32(0)
let transactionSubject = PublishSubject<TransactionEvent>()

struct PahkatClientError: Error {
    let message: String
}

func processPackageEvents(txEvents: Observable<TransactionEvent>) -> Observable<PackageEvent> {
    return txEvents.flatMapLatest { (e: TransactionEvent) -> Observable<PackageEvent> in
        switch e.event {
        case .package:
            if let package = e.packageEvent {
                return Observable.just(package)
            } else {
                return Observable.error(PahkatClientError(message: "Package event received but no package."))
            }
        case .error:
            return Observable.error(PahkatClientError(message: e.error ?? "Unknown error"))
        default:
            return Observable.empty()
        }
    }
}

class PahkatTransaction: PahkatTransactionType {
    private let client: PahkatClient
    private let handle: OpaquePointer
    private let actions: [UnsafeMutablePointer<pahkat_action_t>]
    
    internal init(client: PahkatClient, actions: [TransactionAction]) {
        self.client = client
        self.actions = actions.map { $0.toCType() }
        
        var errors: UnsafeMutablePointer<pahkat_error_t>? = UnsafeMutablePointer.allocate(capacity: 0)
        self.handle = pahkat_create_package_transaction(
            client.handle, UInt32(self.actions.count), self.actions.map { $0.pointee }, &errors)
        // TODO: check and show errors
    }
    
    func validate() -> Bool {
        var errors: UnsafeMutablePointer<pahkat_error_t>? = nil
        let errorCount = pahkat_validate_package_transaction(client.handle, handle, &errors)
        
        defer {
            if let errors = errors {
//                pahkat_error_free(errors)
            }
        }
        
        var cleanErrors = [(UInt32, String)]()
        
        if var errors = errors, errorCount > 0 {
            for _ in 0..<errorCount {
                cleanErrors.append((
                    errors.pointee.code,
                    String(cString: errors.pointee.message)
                ))
                errors = errors.advanced(by: 1)
            }
        }

        return errorCount == 0
    }
    
    let bag = DisposeBag()
    func process(callback: @escaping (Error?, PackageEvent?) -> ()) {
        transactionIdCount += 1
        let id = transactionIdCount
        
        let observable = processPackageEvents(txEvents: runPackageTransaction(txId: id, client: self.client, txHandle: self.handle))
        
        observable.subscribe(
            onNext: { event in callback(nil, event) },
            onError: { error in callback(error, nil) },
            onCompleted: { callback(nil, nil) }).disposed(by: bag)
    }
    
    deinit {
        // TODO: dealllocate all c actions
    }
}

extension PahkatTransactionType {
    func process() -> Observable<PackageEvent> {
        return Observable<PackageEvent>.create { emitter in
            self.process(callback: { (error, event) in
                if let error = error {
                    emitter.onError(error)
                } else if let event = event {
                    emitter.onNext(event)
                } else {
                    emitter.onCompleted()
                }
            })
            
            return Disposables.create()
        }
    }
}

func runPackageTransaction(txId: UInt32, client: PahkatClient, txHandle: OpaquePointer) -> Observable<TransactionEvent> {
    return transactionSubject
        .do(onSubscribed: {
            DispatchQueue.global(qos: .background).async {
                var errors: UnsafeMutablePointer<pahkat_error_t>? = nil
                let result = pahkat_run_package_transaction(client.handle, txHandle, txId, { (txId, rawId, eventCode) in
                    guard let rawPackageId = rawId else { return }
                    let packageIdUrl = URL(string: String(cString: rawPackageId))!
                    let packageId = AbsolutePackageKey(from: packageIdUrl)
                    let event = PackageEvent(packageId: packageId, event: PackageEventType(rawValue: eventCode) ?? PackageEventType.error)
                    transactionSubject.onNext(TransactionEvent(txId: txId, event: .package, packageEvent: event))
                }, &errors)
                
                if result != 0 {
                    transactionSubject.onNext(TransactionEvent(txId: txId, event: .error))
                } else {
                    transactionSubject.onNext(TransactionEvent(txId: txId, event: .completed))
                }
                
                transactionSubject.onNext(TransactionEvent(txId: txId, event: .dispose))
            }
        })
        .do(onNext: { thing in
            print(thing)
        })
        .filter { $0.txId == txId }
        .takeWhile {
            switch $0.event {
            case .dispose:
                return false
            default:
                return true
            }
        }    
}

fileprivate struct PackageStatus : Codable {
    let status: PackageInstallStatus
    let target: MacOsInstaller.Targets
}

protocol PahkatTransactionType {
    func process(callback: @escaping (Error?, PackageEvent?) -> ())
}

struct PahkatTransactionProxy: PahkatTransactionType {
    let service: PahkatAdminProtocol
    let txId: UInt32
    
    func process(callback: @escaping (Error?, PackageEvent?) -> ()) {
        let txId = self.txId
        
        let observable = transactionSubject
            .do(onNext: { thing in
                print(thing)
            }, onSubscribe: {
                self.service.processTransaction(txId: txId)
            })
            .filter { $0.txId == txId }
            .takeWhile {
                switch $0.event {
                case .dispose:
                    return false
                default:
                    return true
                }
            }
        
        _ = processPackageEvents(txEvents: observable).subscribe(
                onNext: { event in callback(nil, event) },
                onError: { error in callback(error, nil) },
                onCompleted: { callback(nil, nil) })
    }
}

class PahkatClient {
    internal let handle: UnsafeMutableRawPointer
    private let admin = PahkatAdminReceiver()
    
    init?(configPath: String? = nil) {
        if let configPath = configPath {
            let cPath = configPath.cString(using: .utf8)
            
            if let client = pahkat_client_new(cPath) {
                handle = client
            } else {
                return nil
            }
        } else {
            handle = pahkat_client_new(nil)
        }
    }
    
    lazy var configPath: String = {
        let cStr = pahkat_config_path(handle)!
        defer { pahkat_str_free(cStr) }
        return String(cString: cStr)
    }()
    
    func repos() -> [RepositoryIndex] {
        let rawString = pahkat_repos_json(handle)!
        defer { pahkat_str_free(rawString) }
        
        let jsonDecoder = JSONDecoder()
        
        let reposStr = String(cString: rawString)
        let reposJson = reposStr.data(using: .utf8)!
        let repos = try! jsonDecoder.decode([RepositoryIndex].self, from: reposJson)
        
        for repo in repos {
            var statuses: [String: PackageStatusResponse] = [:]
            for packageId in repo.packages.keys {
                var error: UInt32 = 0
                let status = pahkat_status(handle, packageId.cString(using: .utf8), &error)
                
                if status == nil {
                    continue
                }
                
                defer { pahkat_str_free(status) }
                
                let response = try! jsonDecoder.decode(PackageStatus.self, from: String(cString: status!).data(using: .utf8)!)
                statuses[packageId] = PackageStatusResponse(status: response.status, target: response.target.rawValue == "system"
                    ? InstallerTarget.system : InstallerTarget.user)
            }
            repo.set(statuses: statuses)
        }
        
        return repos
    }
    
    public typealias DownloadPackageCallback = @convention(c) (_ rawPackageId: UnsafePointer<Int8>?, _ cur: UInt64, _ max: UInt64) -> Void
    
    func download(packageKey: AbsolutePackageKey, target: InstallerTarget) -> Observable<DownloadProgress> {
        var cKey = packageKey.rawValue.cString(using: .utf8)!
        let cb: DownloadPackageCallback = { (rawPackageId, cur, max) in
            guard let rawPackageId = rawPackageId else { return }
            let packageIdUrl = URL(string: String(cString: rawPackageId))!
            let packageId = AbsolutePackageKey(from: packageIdUrl)
            
            if cur < max {
                downloadProgressSubject.onNext(DownloadProgress(packageId: packageId, status: .progress(downloaded: cur, total: max)))
            } else {
                downloadProgressSubject.onNext(DownloadProgress(packageId: packageId, status: .progress(downloaded: cur, total: max)))
                downloadProgressSubject.onNext(DownloadProgress(packageId: packageId, status: .completed))
                downloadProgressSubject.onNext(DownloadProgress(packageId: packageId, status: .notStarted))
            }
        }
        
        downloadProgressSubject.onNext(DownloadProgress(packageId: packageKey, status: .notStarted))
        
        return downloadProgressSubject
            .filter({ $0.packageId == packageKey })
            .do(onSubscribe: {
                downloadProgressSubject.onNext(DownloadProgress(packageId: packageKey, status: .starting))
                
                DispatchQueue.global(qos: .background).async {
                    var errors: UnsafeMutablePointer<pahkat_error_t>? = nil
                    let ret = pahkat_download_package(self.handle, &cKey, target.numberValue, cb, &errors)
                    if ret > 0 {
                        downloadProgressSubject.onNext(DownloadProgress(packageId: packageKey, status: .error(DownloadError(message: "Error code \(ret)"))))
                        downloadProgressSubject.onNext(DownloadProgress(packageId: packageKey, status: .notStarted))
                    }
                }
            })
            .takeWhile({ if case PackageDownloadStatus.notStarted = $0.status { return false } else { return true } })
    }
    
    private func adminTransaction(of actions: [TransactionAction]) -> Single<PahkatTransactionType> {
        return Single<PahkatTransactionType>.create(subscribe: { emitter in
            let service = self.admin.service(errorCallback: { error in
                emitter(.error(error))
            })
            
            let actionsJSON = try! JSONEncoder().encode(actions)
            
            service.transaction(of: actionsJSON, configPath: self.configPath, withReply: { data in
                guard let map = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    fatalError("Invalid JSON serialisation")
                }
                
                if let x = map["success"], let txId = x as? UInt32 {
                    emitter(.success(PahkatTransactionProxy(service: service, txId: txId)))
                } else if let x = map["error"], let error = x as? String {
                    emitter(.error(PahkatClientError(message: error)))
                } else {
                    emitter(.error(PahkatClientError(message: "The transaction was not created.")))
                }
            })
            
            return Disposables.create()
        })
    }
    
    func transaction(of actions: [TransactionAction]) -> Single<PahkatTransactionType> {
        if actions.contains(where: { $0.target == .system }) {
            return adminTransaction(of: actions)
        } else {
            return Single.just(PahkatTransaction(client: self, actions: actions))
        }
    }
    
    deinit {
        pahkat_client_free(handle)
    }
}

@objc class DownloadProgress : NSObject {
    let packageId: AbsolutePackageKey
    let status: PackageDownloadStatus
    
    init(packageId: AbsolutePackageKey, status: PackageDownloadStatus) {
        self.packageId = packageId
        self.status = status
    }
}

fileprivate let downloadProgressSubject = PublishSubject<DownloadProgress>()

fileprivate extension TransactionAction {
    var numberValue: UInt8 {
        switch self.action {
        case .install:
            return 0
        case .uninstall:
            return 1
        }
    }
    
    func toCType() -> UnsafeMutablePointer<pahkat_action_t> {
        let cPackageKey = self.id.rawValue.cString(using: .utf8)!
        
        print("cpkgkey: \(String(cString: cPackageKey))")
        return pahkat_create_action(self.numberValue, self.target.numberValue, cPackageKey)!
    }
}


extension InstallerTarget {
    var numberValue: UInt8 {
        switch self {
        case .system:
            return 0
        case .user:
            return 1
        }
    }
}
