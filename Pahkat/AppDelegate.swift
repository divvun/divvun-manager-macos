import Cocoa
import RxSwift
import Sentry
import XCGLogger

enum TopLevelView {
    case download
    case install
    case completion
    case main
    
    func makeView() -> NSViewController {
        switch self {
        case .main: return MainViewController()
        case .download: return DownloadViewController()
        case .install: return InstallViewController()
        case .completion: return CompletionViewController()
        }
    }
}

extension TransactionEvent {
    var view: TopLevelView {
        switch self {
        case .transactionStarted(_), .downloadComplete(_), .downloadError(_, _), .downloadProgress(_, _, _):
            return .download
        case .installStarted(_), .uninstallStarted(_), .transactionProgress:
            return .install
        case .transactionError, .transactionComplete:
            return .completion
        default:
            return .main
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    private let bag = DisposeBag()
    
    @objc func handleReopenEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventManager) {
        if let window = NSApp.windows.filter({ $0.isVisible }).first {
            window.windowController?.showWindow(self)
        } else {
            AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
        }
    }
    
    private var views = [TopLevelView: NSViewController]()
    
    func launchMain() {
        AppContext.currentTransaction
            .map { $0.view }
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { viewKey in
                print("New current transaction state: \(viewKey)")
                if self.views[viewKey] == nil {
                    self.views[viewKey] = viewKey.makeView()
                }
                let view = self.views[viewKey]
                AppContext.windows.show(MainWindowController.self, viewController: view, sender: self)
            }, onError: { e in
                print("\(e)")
            }, onDisposed: {
                print("BYEEEE")
            }).disposed(by: self.bag)
        
        log.debug("Setting event handler for core open event")
        
        // Handle event for reopen window because AppDelegate one is never called…
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleReopenEvent(_:withReplyEvent:)),
            forEventClass: kCoreEventClass,
            andEventID: kAEReopenApplication)
    }
    
    private func configureLogging() {
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "/tmp/divvun-installer.log", fileLevel: .debug)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureLogging()
        
        // Configure Sentry.io
        do {
            Client.shared = try Client(dsn: "https://554b508acddd44e98c5b3dc70f8641c1@sentry.io/1357390")
            try Client.shared?.startCrashHandler()
        } catch let error {
            log.severe(error)
            // Wrong DSN or KSCrash not installed
        }
        
        AppDelegate.instance = self
        
        launchMain()
    }
}
