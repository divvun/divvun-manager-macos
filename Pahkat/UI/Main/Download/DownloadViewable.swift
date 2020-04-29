import Foundation
import RxSwift
import RxCocoa

protocol DownloadViewable: class {
//    var onCancelTapped: Driver<Void> { get }
    func setStatus(key: PackageKey?, status: PackageDownloadStatus)
    func cancel()
    func initializeDownloads(actions: [ResolvedAction])
    func startInstallation(transaction: TransactionType)
    func handle(error: Error)
}
