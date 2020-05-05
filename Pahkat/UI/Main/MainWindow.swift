import Cocoa
import RxSwift

class MainWindow: Window {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleButton: NSButton!
}

enum Route {
    case main
    case install
    case download
    case complete
    case error
}

class MainWindowController: WindowController<MainWindow> {
    private let bag = DisposeBag()
    
    private func handleError() {
        AppContext.currentTransaction.take(1).subscribe(onNext: { tx in
            DispatchQueue.main.async {
                switch tx {
                case let .error(error):
                    let alert = NSAlert()
                    alert.messageText = Strings.downloadError
                    alert.informativeText = String(describing: error)
                    
                    alert.alertStyle = .critical
                    log.error(error)
                    alert.runModal()
                default:
                    break
                }
                
                AppContext.windows.set(MainViewController(), for: MainWindowController.self)
            }
        }).disposed(by: bag)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        AppContext.currentTransaction
            .asObservable()
            .map({ tx -> Route in
                switch tx {
                case .notStarted:
                    return .main
                case let .inProgress(progress):
                    switch progress.state {
                    case .installing:
                        return .install
                    case .downloading:
                        return .download
                    case .completed:
                        return .complete
                    }
                case .error:
                    return Route.error
                }
            })
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] route in
                print("Setting route to: \(route)")
                
                switch route {
                case .main:
                    AppContext.windows.set(MainViewController(), for: MainWindowController.self)
                    return
                case .download:
                    AppContext.windows.set(DownloadViewController(), for: MainWindowController.self)
                    return
                case .install:
                    AppContext.windows.set(InstallViewController(), for: MainWindowController.self)
                    return
                case .complete:
                    AppContext.windows.set(CompletionViewController(), for: MainWindowController.self)
                    return
                case .error:
                    self?.handleError()
                    return
                }
            })
            .disposed(by: bag)
    }
}
