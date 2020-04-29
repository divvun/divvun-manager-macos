import Foundation
import RxSwift
import RxCocoa

protocol InstallViewable: class {
//    var onCancelTapped: Driver<Void> { get }
    func set(totalPackages total: Int)
    func set(nextPackage: Descriptor, action: PackageActionType)
    func handle(error: Error)
    func beginCancellation()
    func processCancelled()
}
