import Foundation
import RxSwift
import RxCocoa

protocol DownloadViewable: AnyObject {
//    var onCancelTapped: Driver<Void> { get }
    func cancel()
    func initializeDownloads(actions: [ResolvedAction])
}
