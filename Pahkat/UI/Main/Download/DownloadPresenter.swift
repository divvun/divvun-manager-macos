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
    let transaction: TransactionType
    
    required init(view: DownloadViewable, transaction: TransactionType) {
        self.view = view
        self.transaction = transaction
    }
    
    func downloadablePackages() -> [(PackageKey, Package)] {
//        let actions = transaction.actions // .filter { $0.action == .install }
//
//        let repos = try! AppContext.client.repoIndexesWithStatuses()
//        return actions.compactMap { (action) -> (PackageKey, Package)? in
//            for repo in repos {
//                if let package = repo.package(for: action.id) {
//                    return (action.id, package)
//                }
//            }
//            return nil
//        }
        todo()
    }
    
    private var isCancelled = false
    private var packages: [(Descriptor, Release)] = []
    
    private func bindCancel() -> Disposable {
        return view.onCancelTapped.drive(onNext: { [weak self] in
            self?.isCancelled = true
            self?.view.cancel()
        })
    }
    
    private enum DownloadState {
        case completed(PackageKey)
        case error(Error)
        case cancelled
    }
    
    private let downloadedSubject = PublishSubject<DownloadState>()
    
    private func bindDownload() -> Disposable {
        todo()
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
//        return CompositeDisposable(disposables: [
//            self.bindDownload(),
//            self.bindCancel()
//        ])
        todo()
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
