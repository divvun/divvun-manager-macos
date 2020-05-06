import Foundation
import RxSwift

class AppContextImpl {
    let settings: Settings
    let windows = { WindowManager() }()
    let packageStore: PahkatClientType

    // fun stuff for the download/install views
    var cancelTransactionCallback: (() -> Completable)?
    let disposeBag = DisposeBag()

    static func mock() -> TransactionState {
        let actions = [
            ResolvedAction(
                action: .init(
                    key: try! PackageKey.from(urlString: "https://x.brendan.so/packages/speller-sme"),
                    action: .install,
                    target: .system
                ),
                name: ["en": "Test Package"],
                version: "420.69"
            ),
            ResolvedAction(
                action: .init(
                    key: try! PackageKey.from(urlString: "https://x.brendan.so/packages/speller-smn"),
                    action: .install,
                    target: .system
                ),
                name: ["en": "Other Package"],
                version: "2.69"
            )
        ]

        let installingState = TransactionProcessState.installing(current: actions[0].action.key)
//        let processState = TransactionProcessState.defaultDownloading(for: actions, current: 100, total: 100)
        let state = TransactionProgressState(actions: actions, isRebootRequired: false, state: installingState)

//        return .error("Datorn brrr inte")
        return .inProgress(state)
    }

    let currentTransaction = BehaviorSubject<TransactionState>(
//        value: mock()
        value: .notStarted
    )

    private var currentTxDisposable: Disposable? = nil

    func startTransaction(actions: [PackageAction]) {
        let (cancelable, txObservable) = AppContext.packageStore.processTransaction(actions: actions)
        AppContext.cancelTransactionCallback = cancelable

        currentTxDisposable?.dispose()
        currentTxDisposable = Observable.combineLatest(AppContext.currentTransaction, txObservable.distinctUntilChanged()) // (State, Event)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { (state, event) in
                AppContext.currentTransaction.onNext(state.reduce(event: event))
            })
    }

    init() throws {
        settings = try Settings()
        packageStore = MockPahkatClient()
//        packageStore = PahkatClient(unixSocketPath: URL(fileURLWithPath: "/tmp/pahkat"))
    }
}
