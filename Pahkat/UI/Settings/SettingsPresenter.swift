import Foundation
import RxSwift

class SettingsPresenter {
    private unowned let view: SettingsViewable
    
    init(view: SettingsViewable) {
        self.view = view
    }
    
    private func bindRepositoryTable() -> Disposable {
//        return AppContext.settings.state.map { $0.repositories }
//            .flatMapLatest { [weak self] (configs: [RepoRecord]) -> Observable<[RepositoryTableRowData]> in
//                self?.view.updateProgressIndicator(isEnabled: true)
//                return Observable.merge(try configs.map { (config: RepoRecord) -> Observable<RepositoryTableRowData> in
//                    Observable.just(RepositoryTableRowData(name: "❓", url: config.url, channel: config.channel))
////                    return try AppContext.rpc.repository(with: config).asObservable().map { repo in
////                        return RepositoryTableRowData(name: repo.meta.nativeName, url: config.url, channel: config.channel)
////                    }.catchErrorJustReturn(RepositoryTableRowData(name: "❓", url: config.url, channel: config.channel))
//                }).toArray()
//            }
//            .observeOn(MainScheduler.instance)
//            .subscribeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] rowData in
//                self?.view.setRepositories(repositories: rowData)
//                self?.view.updateProgressIndicator(isEnabled: false)
//            }, onError: { [weak self] error in
//                self?.view.handle(error: error)
//            })
        todo()
    }
    
    func start() -> Disposable {
        return CompositeDisposable(disposables: [
            bindRepositoryTable()
        ])
    }
}
