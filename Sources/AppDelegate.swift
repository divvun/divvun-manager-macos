import Cocoa
import RxSwift
import Sentry
import XCGLogger

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    private let bag = DisposeBag()
    
    @objc func handleReopenEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventManager) {
        if let window = NSApp.windows.filter({ $0.isVisible }).first {
            window.windowController?.showWindow(self)
        } else {
            AppContext.windows.show(MainWindowController.self)
        }
    }
    
    func launchMain() {
        AppContext.windows.show(MainWindowController.self)
        
        log.debug("Setting event handler for core open event")
        
        // Handle event for reopen window because AppDelegate one is never called…
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleReopenEvent(_:withReplyEvent:)),
            forEventClass: kCoreEventClass,
            andEventID: kAEReopenApplication)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure Sentry.io
        do {
            Client.shared = try Client(dsn: "https://554b508acddd44e98c5b3dc70f8641c1@sentry.io/1357390")
            try Client.shared?.startCrashHandler()
        } catch let error {
            log.severe(error)
            // Wrong DSN or KSCrash not installed
        }
        
        AppDelegate.instance = self

        AppContext.packageStore.notifications().subscribe(onNext: {
            switch $0 {
            case .rpcStopping:
                log.info("RPC is stopping.")
            case .rebootRequired:
                log.info("A reboot is required.")
            case .repositoriesChanged:
                log.info("Repository data has changed on the RPC.")
            }
        }).disposed(by: bag)
        
        launchMain()
    }
}
