//
//  DownloadPresenter.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class DownloadPresenter {
    private weak var view: DownloadViewable!
    let actions: [PackageAction]
    
    required init(view: DownloadViewable, actions: [PackageAction]) {
        self.view = view
        self.actions = actions
    }
    
    private var isCancelled = false
    private var packages: [(Descriptor, Release)] = []
    
    private func bindCancel() -> Disposable {
//        return view.onCancelTapped.drive(onNext: { [weak self] in
//            self?.isCancelled = true
//            self?.view.cancel()
//        })
        Disposables.create()
    }
    
    private enum DownloadState {
        case remainingDownloads(Int)
        case error(PackageKey?, String?)
        case cancelled
        case done
        
        var hasCompleted: Bool {
            switch self {
            case .remainingDownloads(_):
                return false
            default: return true
            }
        }
    }
    
    private func bindDownload() -> Disposable {
//        let (cancelable, stream) = AppContext.packageStore.processTransaction(actions: actions)
//        let downloadCount = actions.filter { $0.action == .install }.count
//        let start = DownloadState.remainingDownloads(downloadCount)
        
//        let actions = AppContext.dontTouchThis!.2
        
        return AppContext.currentTransaction.subscribe(onNext: { event in
            switch event {
            case let .transactionStarted:
                self.view.initializeDownloads(packages: [])
            case let .downloadProgress(key, progress, total):
                self.view.setStatus(key: key, status: .progress(downloaded: progress, total: total))
            case let .downloadError(key, error):
                self.view.setStatus(key: key, status: .error(DownloadError(message: Strings.downloadError)))
                self.view.handle(error: DownloadError(message: error ?? "Unknown error"))
            case let .transactionError(_, error):
                self.view.handle(error: DownloadError(message: error ?? "Unknown error"))
            case let .downloadComplete(key):
                self.view.setStatus(key: key, status: .completed)
            default:
                break
            }
        })
//        let stfu = stream
//            .scan(start, accumulator: { (cur, event) in
//                switch event {
//                case let .transactionStarted:
//                    // UI update might go here
//                    return cur
//                case let .downloadProgress(key, progress, total):
//                    // UI update goes here
//                    return cur
//                case let .downloadError(key, error):
//                    // UI update goes here
//                    return .error(key, error)
//                case let .transactionError(key, error):
//                    return .error(key, error)
//                case let .downloadComplete(key):
//                    if case let .remainingDownloads(x) = cur {
//                        if x == 0 {
//                            return .done
//                        }
//                        return .remainingDownloads(x - 1)
//                    } else {
//                        return .error(key, "Invalid state: \(cur)")
//                    }
//                default:
//                    break
//                }
//
//                return cur
//            })
//            .filter { $0.hasCompleted }
//            .take(1)
//            .map { state in
//                switch state {
//                case let .error(key, error):
//                    break
//                case let .done:
//                    break
//                case let .cancelled:
//                    break
//                default:
//                    break
//                }
//            }
        
//        onNext: { event in
//
//        }, onError: { [weak self] in
//            self?.view.handle(error: $0)
//        })
//        let client = AppContext.client
//
//        let downloadables = downloadablePackages()
//        downloadables.forEach { (k, v) in packages[k] = v }
//
//        let downloadableObservable = Observable.from(downloadables)
//        return downloadableObservable.map { (key, package) -> Completable in
//            if self.isCancelled {
//                return Completable.empty()
//            }
//
//            client.download(packageKey: key, delegate: self)
//
//            return self.downloadedSubject.map { (event) -> Completable? in
//                switch event {
//                case let .error(error):
//                    return Completable.error(error)
//                case .cancelled:
//                    return Completable.empty()
//                case let .completed(k):
//                    return key == k ? Completable.empty() : nil
//                }
//            }
//            .filter { $0 != nil }
//            .map { $0! }
//            .take(1)
//            .switchLatest()
//            .asCompletable()
//        }
//        .merge(maxConcurrent: 3)
//        .toArray()
//        .observeOn(MainScheduler.instance)
//        .subscribeOn(MainScheduler.instance)
//        .subscribe(
//            onNext: { [weak self] _ in
//                guard let `self` = self else { return }
//                if !self.isCancelled {
//                    self.view.startInstallation(transaction: self.transaction)
//                }
//            },
//            onError: { [weak self] in
//                self?.view.handle(error: $0)
//            }
//        )
    }
        
    func start() -> Disposable {
//        self.view.initializeDownloads(packages: downloadablePackages().map { $0.1 })
//
        return CompositeDisposable(disposables: [
            self.bindDownload(),
            self.bindCancel()
        ])
    }
}

//extension DownloadPresenter: PackageDownloadDelegate {
//    var isDownloadCancelled: Bool {
//        return self.isCancelled
//    }
//
//    func downloadDidProgress(_ packageKey: PackageKey, current: UInt64, maximum: UInt64) {
//        guard let package = self.packages[packageKey] else { return }
//        self.view.setStatus(
//            package: package,
//            status: .progress(downloaded: current, total: maximum))
//    }
//
//    func downloadDidComplete(_ packageKey: PackageKey, path: String) {
//        guard let package = self.packages[packageKey] else { return }
//        self.view.setStatus(
//            package: package,
//            status: .completed)
//        downloadedSubject.onNext(.completed(packageKey))
//    }
//
//    func downloadDidCancel(_ packageKey: PackageKey) {
//        guard let package = self.packages[packageKey] else { return }
//        self.view.setStatus(
//            package: package,
//            status: .notStarted)
//        downloadedSubject.onNext(.cancelled)
//    }
//
//    func downloadDidError(_ packageKey: PackageKey, error: Error) {
//        guard let package = self.packages[packageKey] else { return }
//        self.view.setStatus(
//            package: package,
//            status: .error(DownloadError(message: error.localizedDescription)))
//        downloadedSubject.onNext(.error(error))
//    }
//}
