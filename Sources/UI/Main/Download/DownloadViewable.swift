import Foundation
import RxSwift
import RxCocoa

protocol DownloadViewable: class {
//    var onCancelTapped: Driver<Void> { get }
    func cancel()
    func initializeDownloads(actions: [ResolvedAction])
}
