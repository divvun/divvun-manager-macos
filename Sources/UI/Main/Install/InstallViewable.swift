import Foundation
import RxSwift
import RxCocoa

protocol InstallViewable: class {
//    var onCancelTapped: Driver<Void> { get }
    func set(totalPackages total: Int)
    func set(nextPackage resolvedAction: ResolvedAction)
    func handle(error: String)
    func beginCancellation()
    func processCancelled()
}
