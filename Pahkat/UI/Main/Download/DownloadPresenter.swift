import Foundation
import RxSwift

class DownloadPresenter {
    private weak var view: DownloadViewable!
    
    required init(view: DownloadViewable) {
        self.view = view
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
        
    func start() -> Disposable {
        return CompositeDisposable(disposables: [
            self.bindCancel()
        ])
    }
}
