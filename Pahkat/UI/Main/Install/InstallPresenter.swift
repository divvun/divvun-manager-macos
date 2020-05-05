import Foundation
import RxSwift


class InstallPresenter {
    private unowned var view: InstallViewable
    private let transaction: TransactionType
    private let repos: [LoadedRepository]
    
    private var isCancelled = false
//    private var cancelCallback: CancelCallback? = nil
    private var requiresReboot = false
    
    init(view: InstallViewable, transaction: TransactionType, repos: [LoadedRepository]) {
        self.view = view
        self.transaction = transaction
        self.repos = repos
    }
    
    private func bindCancelButton() -> Disposable {
//        return view.onCancelTapped.drive(onNext: { [weak self] in
//            self?.isCancelled = true
////            self?.cancelCallback?()
//            self?.view.beginCancellation()
//        })
        return Disposables.create()
    }

    private func bindInstall() -> Disposable {
        return AppContext.currentTransaction.subscribe(onNext: { event in
            switch event {
            case let .installStarted(packageKey: key):
                // TODO: update view
                break
            case .transactionComplete:
                // TODO: something here?
                break
            default:
                break
            }
        })
    }
    
    private func package(for key: PackageKey) -> Package {
//        for repo in repos {
//            if let pkg = repo.package(for: key) {
//                return pkg
//            }
//        }
//        fatalError("No package found during installation with key: \(key.rawValue)")
        todo()
    }
    
    func start() -> Disposable {
//        self.view.set(totalPackages: transaction.actions.count)
//
//        cancelCallback = transaction.processWithCallback(delegate: self)
//
//        return bindCancelButton()
        todo()
    }
}

//extension InstallPresenter: PackageTransactionDelegate {
//    func isTransactionCancelled(_ id: UInt32) -> Bool {
//        return self.isCancelled
//    }
//
//    func transactionWillInstall(_ id: UInt32, packageKey: PackageKey) {
////        let package = self.package(for: packageKey)
////        if package.macOSInstaller?.requiresReboot ?? false {
////            requiresReboot = true
////        }
////        self.view.set(nextPackage: package, action: .install)
//        todo()
//    }
//
//    func transactionWillUninstall(_ id: UInt32, packageKey: PackageKey) {
////        let package = self.package(for: packageKey)
////        if package.macOSInstaller?.requiresUninstallReboot ?? false {
////            requiresReboot = true
////        }
////        self.view.set(nextPackage: package, action: .uninstall)
//        todo()
//    }
//
//    func transactionDidCancel(_ id: UInt32) {
//        self.view.processCancelled()
//    }
//
//    func transactionDidComplete(_ id: UInt32) {
//        self.view.showCompletion(requiresReboot: requiresReboot)
//    }
//
//    func transactionDidError(_ id: UInt32, packageKey: PackageKey?, error: Error?) {
//        todo()
//    }
//
//    func transactionDidUnknownEvent(_ id: UInt32, packageKey: PackageKey, event: UInt32) {
//        // Do nothing.
//    }
//}
