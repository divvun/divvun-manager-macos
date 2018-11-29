//
//  PahkatClientService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-11-25.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct PackageEvent {
    let packageId: AbsolutePackageKey
    let event: PackageEventType
}

enum PackageEventType: UInt32 {
    case notStarted = 0
    case uninstalling = 1
    case installing = 2
    case completed = 3
    case error = 4
}

struct TransactionEvent {
    let txId: UInt32
    let event: TransactionEventType
}

enum TransactionEventType {
    case package(PackageEvent)
    case completed
    case error
    case dispose
}

fileprivate var transactionIdCount = UInt32(0)
fileprivate let transactionSubject = PublishSubject<TransactionEvent>()

struct PahkatClientError: Error {
    let message: String
}

class PahkatTransaction {
    private let client: PahkatClient
    private let handle: OpaquePointer
    private let actions: [UnsafeMutablePointer<pahkat_action_t>]
    
    fileprivate init(client: PahkatClient, actions: [PackageAction]) {
        self.client = client
        self.actions = actions.map { $0.toCType() }
        
        self.handle = pahkat_create_package_transaction(
            client.handle, UInt32(self.actions.count), self.actions.map { $0.pointee })
        
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
    
    func process() -> Observable<PackageEvent> {
        transactionIdCount += 1
        let txId = transactionIdCount
        
        return transactionSubject
            .do(onSubscribed: {
                DispatchQueue.global(qos: .background).async {
                    let result = pahkat_run_package_transaction(self.client.handle, self.handle, txId,  { (txId, rawId, eventCode) in
                        guard let rawPackageId = rawId else { return }
                        let packageIdUrl = URL(string: String(cString: rawPackageId))!
                        let packageId = AbsolutePackageKey(from: packageIdUrl)
                        let event = PackageEvent(packageId: packageId, event: PackageEventType(rawValue: eventCode) ?? PackageEventType.error)
                        transactionSubject.onNext(TransactionEvent(txId: txId, event: .package(event)))
                    })
                    
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
            .flatMapLatest { (e: TransactionEvent) -> Observable<PackageEvent> in
                switch e.event {
                case let .package(package):
                    return Observable.just(package)
                case .error:
                    return Observable.error(PahkatClientError(message: "An error"))
                default:
                    return Observable.empty()
                }
            }
        
        
    }
    
    deinit {
        // TODO: dealllocate all c actions
    }
}

class PahkatClient {
    fileprivate let handle: UnsafeMutableRawPointer
    
    init() {
        handle = pahkat_client_new()
    }
    
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
                
                let response = try! jsonDecoder.decode(PackageStatusResponse.self, from: String(cString: status!).data(using: .utf8)!)
                statuses[packageId] = response
            }
            repo.set(statuses: statuses)
        }
        
        return repos
    }
    
    public typealias DownloadPackageCallback = @convention(c) (_ rawPackageId: UnsafePointer<Int8>?, _ cur: UInt64, _ max: UInt64) -> Void
    
    func download(packageKey: AbsolutePackageKey, target: MacOsInstaller.Targets) -> Observable<DownloadProgress> {
        var cKey = packageKey.rawValue.cString(using: .utf8)!
        let cb: DownloadPackageCallback = { (rawPackageId, cur, max) in
            guard let rawPackageId = rawPackageId else { return }
            let packageIdUrl = URL(string: String(cString: rawPackageId))!
            let packageId = AbsolutePackageKey(from: packageIdUrl)
            
            if cur < max {
                downloadProgressSubject.onNext((packageId: packageId, status: .progress(downloaded: cur, total: max)))
            } else {
                downloadProgressSubject.onNext((packageId: packageId, status: .progress(downloaded: cur, total: max)))
                downloadProgressSubject.onNext((packageId: packageId, status: .completed))
                downloadProgressSubject.onNext((packageId: packageId, status: .notStarted))
            }
        }
        
        downloadProgressSubject.onNext((packageId: packageKey, status: .notStarted))
        
        return downloadProgressSubject
            .filter({ $0.packageId == packageKey })
            .do(onSubscribe: {
                downloadProgressSubject.onNext((packageId: packageKey, status: .starting))
                
                DispatchQueue.global(qos: .background).async {
                    let ret = pahkat_download_package(self.handle, &cKey, target.numberValue, cb)
                    if ret > 0 {
                        downloadProgressSubject.onNext((packageId: packageKey, status: .error(DownloadError(message: "Error code \(ret)"))))
                        downloadProgressSubject.onNext((packageId: packageKey, status: .notStarted))
                    }
                }
            })
            .takeWhile({ if case PackageDownloadStatus.notStarted = $0.1 { return false } else { return true } })
    }
    
    func transaction(of actions: [PackageAction]) -> PahkatTransaction {
        return PahkatTransaction(client: self, actions: actions)
    }
    
    deinit {
        pahkat_client_free(handle)
    }
}

typealias DownloadProgress = (packageId: AbsolutePackageKey, status: PackageDownloadStatus)
fileprivate let downloadProgressSubject = PublishSubject<DownloadProgress>()

fileprivate extension PackageAction {
    var numberValue: UInt8 {
        switch self {
        case .install:
            return 0
        case .uninstall:
            return 1
        }
    }
    
    func toCType() -> UnsafeMutablePointer<pahkat_action_t> {
        let cPackageKey = self.packageRecord.id.rawValue.cString(using: .utf8)!
        return pahkat_create_action(self.numberValue, self.target.numberValue, cPackageKey)!
    }
}



extension MacOsInstaller.Targets {
    var numberValue: UInt8 {
        switch self {
        case .system:
            return 0
        case .user:
            return 1
        }
    }
}
