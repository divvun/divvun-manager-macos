import Foundation
import Cocoa
import XCGLogger
import RxSwift

struct DownloadProgress: Equatable {
    let current: UInt64
    let total: UInt64
    
    init(_ a: UInt64, _ b: UInt64) {
        current = a
        total = b
    }
}

enum TransactionProcessState: Equatable {
    case downloading(state: [PackageKey: DownloadProgress])
    case installing(current: PackageKey)
    case completed
    
    static func defaultDownloading(for actions: [ResolvedAction], current: UInt64 = 0, total: UInt64 = 0) -> TransactionProcessState {
        var out = [PackageKey: DownloadProgress]()
        for action in actions {
            if action.action.action == .install {
                out[action.action.key] = DownloadProgress(current, total)
            }
        }
        return .downloading(state: out)
    }
}

struct TransactionProgressState: Equatable {
    let actions: [ResolvedAction]
    let isRebootRequired: Bool
    private(set) var state: TransactionProcessState
    
    func copy(with state: TransactionProcessState) -> TransactionProgressState {
        var copied = self
        copied.state = state
        return copied
    }
}

enum TransactionState: Equatable {
    case notStarted
    case inProgress(TransactionProgressState)
    case error(String)
    
    var isNotStarted: Bool {
        switch self {
        case .notStarted:
            return true
        default:
            return false
        }
    }
    
    var isInProgress: Bool {
        switch self {
        case .inProgress:
            return true
        default:
            return false
        }
    }
    
    var isError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }

    func reduce(event: TransactionEvent) -> TransactionState {
        switch event {
        case let .transactionStarted(actions, isRebootRequired):
            return TransactionState.inProgress(TransactionProgressState(
                actions: actions,
                isRebootRequired: isRebootRequired,
                state: .defaultDownloading(for: actions)))
        case let .downloadProgress(key, current, total):
            if case let .inProgress(progress) = self {
                if case let .downloading(dl) = progress.state {
                    var map = dl
                    map[key] = DownloadProgress(current, total)
                    return .inProgress(progress.copy(with: .downloading(state: map)))
                }
            }
        case let .installStarted(packageKey: key), let .uninstallStarted(packageKey: key):
            if case let .inProgress(progress) = self {
                return .inProgress(progress.copy(with: .installing(current: key)))
            }
        case .transactionComplete:
            if case let .inProgress(progress) = self {
                return .inProgress(progress.copy(with: .completed))
            }
        case let .transactionError(packageKey: _, error: message):
            return .error(message ?? Strings.downloadError)
            
        // We don't need to handle these two
        case .downloadComplete, .transactionProgress:
            break
        }
        
        return self
    }
}

public func todo() -> Never {
    fatalError("Function not implemented")
}

var AppContext: AppContextImpl!

let log = XCGLogger.default

class App: NSApplication {
    private lazy var appDelegate = AppDelegate()
    
    override init() {
        super.init()
        
        self.delegate = appDelegate
        
        do {
            AppContext = try AppContextImpl()
        } catch let error {
            // TODO: show an NSAlert to the user indicating the actual problem and how to fix it
            fatalError("\(error)")
        }
        
        let language: String? = AppContext.settings.read(key: .language)
        
        if let language = language {
            UserDefaults.standard.set([language], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    override func terminate(_ sender: Any?) {
        AppContext = nil
        super.terminate(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
