import Cocoa
import RxSwift

class MainWindow: Window {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleButton: NSButton!
}

enum Route {
    case landing
    case detailed
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

                AppContext.currentTransaction.onNext(.notStarted)
            }
        }).disposed(by: bag)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        Observable.combineLatest(router(), AppContext.settings.selectedRepository)
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tuple: (Route, URL?)) in
                switch tuple.0 {
                case .landing:
                    self?.showLandingPage(url: tuple.1)
                default:
                    break
                }
            })
            .disposed(by: bag)

        router()
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] route in
                print("Setting route to: \(route)")
                
                switch route {
                case .landing:
                    AppContext.windows.set(LandingViewController(), for: MainWindowController.self)
                    return
                case .detailed:
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

    private func router() -> Observable<Route> {
        return AppContext.currentTransaction
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .map({ tx -> Route in
                switch tx {
                case .notStarted:
                    return .landing
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
    }

    private func showLandingPage(url: URL?) {
        if url != nil && url?.scheme == "divvun-installer" {
            AppContext.windows.set(MainViewController(), for: MainWindowController.self)
        } else {
            AppContext.windows.set(LandingViewController(), for: MainWindowController.self)
        }
    }
}
