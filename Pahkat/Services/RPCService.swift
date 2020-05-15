import Foundation
import GRPC
import NIO
import RxSwift

enum TransactionEvent: Equatable {
    case transactionStarted(actions: [ResolvedAction], isRebootRequired: Bool)
    case transactionComplete
    case transactionProgress(packageKey: PackageKey, message: String?, current: UInt64, total: UInt64)
    case transactionError(packageKey: PackageKey?, error: String?)
    case downloadProgress(packageKey: PackageKey, current: UInt64, total: UInt64)
    case downloadComplete(packageKey: PackageKey)
    case installStarted(packageKey: PackageKey)
    case uninstallStarted(packageKey: PackageKey)

    var isFinal: Bool {
        switch self {
        case .transactionComplete, .transactionError:
            return true
        default:
            return false
        }
    }
}


enum PackageStatus: Int32, Codable {
    case notInstalled = 0
    case upToDate = 1
    case requiresUpdate = 2
    
    case errorNoPackage = -1
    case errorNoPayloadFound = -2
    case errorWrongPayloadType = -3
    case errorParsingVersion = -4
    case errorCriteriaUnmet = -5
    
    case errorUnknownStatus = -2147483648 // min Int32
    
    var isError: Bool {
        return self.rawValue < 0
    }
}

enum PahkatNotification {
    case rebootRequired
    case repositoriesChanged
    case rpcStopping
}

struct PackageQuery: Codable {
    let tags: [String]?
}

protocol PahkatClientType: class {
    func notifications() -> Observable<PahkatNotification>
    func repoIndexes() -> Single<[LoadedRepository]>
    func status(packageKey: PackageKey) -> Single<(PackageStatus, SystemTarget)>
    func processTransaction(actions: [PackageAction]) -> (() -> Completable, Observable<TransactionEvent>)
    func strings(languageTag: String) -> Single<[URL: MessageMap]>
    func setRepo(url: URL, record: RepoRecord) -> Single<[URL: RepoRecord]>
    func getRepoRecords() -> Single<[URL: RepoRecord]>
    func removeRepo(url: URL) -> Single<[URL: RepoRecord]>
    func resolvePackageQuery(query: PackageQuery) -> Single<Data>
}

struct MessageMap {
    let channels: [String: String]
    let tags: [String: String]
}

class MockPahkatClient: PahkatClientType {
    var records = [URL: RepoRecord]()

    func notifications() -> Observable<PahkatNotification> {
        return Observable.just(PahkatNotification.repositoriesChanged)
    }

    func strings(languageTag: String) -> Single<[URL : MessageMap]> {
        return Single.just([:])
    }

    func setRepo(url: URL, record: RepoRecord) -> Single<[URL : RepoRecord]> {
        records[url] = record
        return Single.just(records)
    }

    func getRepoRecords() -> Single<[URL : RepoRecord]> {
        return Single.just(records)
    }

    func removeRepo(url: URL) -> Single<[URL : RepoRecord]> {
        records.removeValue(forKey: url)
        return Single.just(records)
    }

    func repoIndexes() -> Single<[LoadedRepository]> {
        return Single.just([
            LoadedRepository.mock(id: "1"),
            LoadedRepository.mock(id: "2"),
            LoadedRepository.mock(id: "3")
        ])
    }

    func status(packageKey: PackageKey) -> Single<(PackageStatus, SystemTarget)> {
        return Single.just((.notInstalled, .system))
    }

    func processTransaction(actions: [PackageAction]) -> (() -> Completable, Observable<TransactionEvent>) {
        let completable = { Completable.empty() }

        var fakeEvents = [TransactionEvent]()

        let resolvedActions = actions.map {
            ResolvedAction(action: $0, name: ["en": "Supreme keyboard"], version: "2.0")
        }

        fakeEvents.append(TransactionEvent.transactionStarted(actions: resolvedActions, isRebootRequired: false))

        resolvedActions.forEach { action in
            if action.actionType == .install {
                fakeEvents.append(.downloadProgress(packageKey: action.key, current: 0, total: 100))
                fakeEvents.append(.downloadProgress(packageKey: action.key, current: 33, total: 100))
                fakeEvents.append(.downloadProgress(packageKey: action.key, current: 66, total: 100))
                fakeEvents.append(.downloadProgress(packageKey: action.key, current: 100, total: 100))
            }
        }

        resolvedActions.forEach { action in
            if action.actionType == .install {
                fakeEvents.append(.downloadComplete(packageKey: action.key))
            }
        }

        resolvedActions.forEach { action in
            if action.actionType == .install {
                fakeEvents.append(.installStarted(packageKey: action.key))
            } else {
                fakeEvents.append(.uninstallStarted(packageKey: action.key))
            }
        }

        fakeEvents.append(.transactionComplete)

        let observable = Observable.from(fakeEvents)

        return (completable, observable)
    }

    func resolvePackageQuery(query: PackageQuery) -> Single<Data> {
        return Single.just("[]".data(using: .utf8)!)
    }
}

class PahkatClient: PahkatClientType {
    private let path: URL
    private lazy var monitor = { Monitor(client: self) }()
    private lazy var inner: Pahkat_PahkatClient = {
        Self.connect(path: self.path, delegate: self.monitor)
    }()

    public func notifications() -> Observable<PahkatNotification> {
        return Observable<PahkatNotification>.create { emitter in
            let _ = self.inner.notifications(Pahkat_NotificationsRequest(), handler: { response in
                switch response.value {
                case .rebootRequired:
                    emitter.onNext(.rebootRequired)
                case .repositoriesChanged:
                    emitter.onNext(.repositoriesChanged)
                case .rpcStopping:
                    emitter.onNext(.rpcStopping)
                default:
                    log.error("Unhandled notification: \(response.value)")
                }
            })

            return Disposables.create()
        }
    }
    
    public func repoIndexes() -> Single<[LoadedRepository]> {
        let req = Pahkat_RepositoryIndexesRequest()
        let res = self.inner.repositoryIndexes(req)
        
        return Single<[LoadedRepository]>.create { emitter in
            res.response.whenSuccess { value in
                do {
                    let repos = try value.repositories.map {
                        try LoadedRepository.from(protobuf: $0)
                    }
                    emitter(.success(repos))
                } catch let error {
                    emitter(.error(error))
                }
            }
            
            res.response.whenFailure {
                emitter(.error($0))
            }
            
            return Disposables.create()
        }
    }
    
    private func status(packageKey: PackageKey, target: SystemTarget) -> Single<(PackageStatus, SystemTarget)> {
        var req = Pahkat_StatusRequest()
        req.packageID = packageKey.toString()
        req.target = target.intValue
        let res = self.inner.status(req)
        
        return Single<(PackageStatus, SystemTarget)>.create { emitter in
            res.response.whenSuccess { value in
                print("Success: \(packageKey) \(value.value)")
                let status = PackageStatus(rawValue: value.value) ?? PackageStatus.errorUnknownStatus
                emitter(.success((status, target)))
            }
            
            res.response.whenFailure {
                print("Error: \(packageKey) \($0)")
                emitter(.error($0))
            }
            
            return Disposables.create()
        }
    }
    
    public func status(packageKey: PackageKey) -> Single<(PackageStatus, SystemTarget)> {
        self.status(packageKey: packageKey, target: .user).catchError { _ in
            self.status(packageKey: packageKey, target: .system)
        }
    }

    public func processTransaction(actions: [PackageAction]) -> (() -> Completable, Observable<TransactionEvent>) {
        let subject = ReplaySubject<TransactionEvent>.createUnbounded()
        
        let responseCallback: (Pahkat_TransactionResponse) -> Void = { response in
            guard let value = response.value else {
                // TODO: maybe? An error? Maybe.
                return
            }
            
            let event: TransactionEvent
            
            switch value {
            case let .transactionStarted(res):
                do {
                    let resActions = try res.actions.map { try ResolvedAction.from($0) }
                    event = .transactionStarted(actions: resActions, isRebootRequired: res.isRebootRequired)
                } catch {
                    event = .transactionError(packageKey: nil, error: "Invalid response from RPC service.")
                }
            case .transactionComplete(_):
                event = .transactionComplete
            case let .transactionProgress(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                let message = res.message == "" ? nil : res.message

                event = .transactionProgress(
                    packageKey: packageKey!,
                    message: message,
                    current: res.current,
                    total: res.total)
            case let .transactionError(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                let error = res.error == "" ? nil : res.error
                
                event = .transactionError(
                    packageKey: packageKey,
                    error: error
                )
            case let .downloadProgress(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .downloadProgress(
                    packageKey: packageKey!,
                    current: res.current,
                    total: res.total)
            case let .downloadComplete(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .downloadComplete(packageKey: packageKey!)
            case let .installStarted(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .installStarted(packageKey: packageKey!)
            case let .uninstallStarted(res):
                let packageKey = try? PackageKey.from(urlString: res.packageID)
                event = .uninstallStarted(packageKey: packageKey!)
            }
            subject.onNext(event)
        }
        
        let sender = self.inner.processTransaction(handler: responseCallback)
        
        var req = Pahkat_TransactionRequest()

        var transaction = Pahkat_TransactionRequest.Transaction()
        transaction.actions = actions.map { action in
            var a = Pahkat_PackageAction()
            a.id = action.key.toString()
            a.action = UInt32(action.action.rawValue)
            a.target = action.target.intValue
            return a
        }
        req.transaction = transaction
        
        let _ = sender.sendMessage(req)
        
        let cancelCallback: () -> Completable = {
            var req = Pahkat_TransactionRequest()
            req.cancel = Pahkat_TransactionRequest.Cancel()
            let response = sender.sendMessage(req)
            
            return Completable.create { emitter in
                response.whenSuccess({ emitter(.completed) })
                response.whenFailure({ emitter(.error($0)) })
                
                return Disposables.create {}
            }
        }
        
        return (
            cancelCallback,
            subject.asObservable()
        )
    }

    func strings(languageTag: String) -> Single<[URL: MessageMap]> {
        var req = Pahkat_StringsRequest()
        req.language = languageTag

        return Single<[URL: MessageMap]>.create { emitter in
            let res = self.inner.strings(req)

            res.response.whenSuccess { response in
                var out = [URL: MessageMap]()

                for (key, value) in response.repos {
                    guard let key = URL(string: key) else { continue }
                    out[key] = MessageMap(channels: value.channels, tags: value.tags)
                }

                emitter(.success(out))
            }

            res.response.whenFailure {
                emitter(.error($0))
            }

            return Disposables.create()
        }
    }

    func setRepo(url: URL, record: RepoRecord) -> Single<[URL : RepoRecord]> {
        var req = Pahkat_SetRepoRequest()
        req.url = url.absoluteString

        var settings = Pahkat_RepoRecord()
        if let channel = record.channel {
            settings.channel = channel
        }
        req.settings = settings


        return Single<[URL: RepoRecord]>.create { emitter in
            let res = self.inner.setRepo(req)

            res.response.whenSuccess { response in
                var out = [URL: RepoRecord]()

                for (key, value) in response.records {
                    guard let key = URL(string: key) else { continue }
                    out[key] = RepoRecord(channel: value.channel)
                }

                emitter(.success(out))
            }

            res.response.whenFailure {
                emitter(.error($0))
            }

            return Disposables.create()
        }
    }

    func getRepoRecords() -> Single<[URL : RepoRecord]> {
        let req = Pahkat_GetRepoRecordsRequest()

        return Single<[URL: RepoRecord]>.create { emitter in
            let res = self.inner.getRepoRecords(req)

            res.response.whenSuccess { response in
                var out = [URL: RepoRecord]()

                for (key, value) in response.records {
                    guard let key = URL(string: key) else { continue }
                    out[key] = RepoRecord(channel: value.channel)
                }

                emitter(.success(out))
            }

            res.response.whenFailure {
                emitter(.error($0))
            }

            return Disposables.create()
        }
    }

    func removeRepo(url: URL) -> Single<[URL : RepoRecord]> {
        var req = Pahkat_RemoveRepoRequest()
        req.url = url.absoluteString

        return Single<[URL: RepoRecord]>.create { emitter in
            let res = self.inner.removeRepo(req)

            res.response.whenSuccess { response in
                var out = [URL: RepoRecord]()

                for (key, value) in response.records {
                    guard let key = URL(string: key) else { continue }
                    out[key] = RepoRecord(channel: value.channel)
                }

                emitter(.success(out))
            }

            res.response.whenFailure {
                emitter(.error($0))
            }

            return Disposables.create()
        }
    }

    func resolvePackageQuery(query: PackageQuery) -> Single<Data> {
        var req = Pahkat_JsonRequest()
        req.json = String(data: try! JSONEncoder().encode(query), encoding: .utf8)!

        return Single<Data>.create { emitter in
            let res = self.inner.resolvePackageQuery(req)

            res.response.whenSuccess { response in
                emitter(.success(response.json.data(using: .utf8)!))
            }

            res.response.whenFailure {
                emitter(.error($0))
            }

            return Disposables.create()
        }
    }

    class Monitor: ConnectivityStateDelegate {
        private weak var client: PahkatClient? = nil

        func connectivityStateDidChange(from oldState: ConnectivityState, to newState: ConnectivityState) {
            log.debug("RPC changed state: \(oldState) -> \(newState)")
//            guard let client = client else { return }
//            switch newState {
//            case .shutdown, .transientFailure:
//                client.inner = PahkatClient.connect(path: client.path, delegate: self)
//            default:
//                return
//            }
        }

        init(client: PahkatClient) {
            self.client = client
        }
    }

    private static func connect(path: URL, delegate: ConnectivityStateDelegate) -> Pahkat_PahkatClient {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        let conn = ClientConnection(
            configuration: .init(target: .unixDomainSocket(path.path),
                                 eventLoopGroup: group))
        conn.connectivity.delegate = delegate

        let client = Pahkat_PahkatClient(channel: conn)

        return client
    }

    init(unixSocketPath path: URL) {
        self.path = path
    }
}


