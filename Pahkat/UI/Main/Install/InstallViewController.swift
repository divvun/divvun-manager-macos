import Cocoa
import RxSwift
import RxCocoa

class InstallViewController: DisposableViewController<InstallView>, InstallViewable, NSToolbarDelegate {
    var onCancelTapped: Driver<Void> {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }
    
    required init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        configureToolbar()
        bindInstall()
    }

    private func bindInstall() {
        AppContext
            .currentTransaction
            .subscribe(onNext: { state in
                switch state {
                case .inProgress(let progressState):
                    self.updateUI(progressState: progressState)
                case .error(let error):
                    // TODO: test this
                    self.handle(error: error)
                    break
                default:
                    break
                }
            })
            .disposed(by: bag)
    }

    private func updateUI(progressState: TransactionProgressState) {
        let actions: [ResolvedAction] = progressState.actions
        set(totalPackages: actions.count)

        let processState = progressState.state
        switch processState {
        case .installing(let key):
            guard let action = (actions.first { $0.action.key == key }) else {
                return
            }
            set(nextPackage: action)
        default:
            break
        }
    }

    private func setRemaining() {
        // Shhhhh
        let max = Int(self.contentView.horizontalIndicator.maxValue)
        let value = Int(self.contentView.horizontalIndicator.doubleValue)
        
        self.contentView.remainingLabel.stringValue = Strings.nItemsRemaining(count: String(max - value))
    }
    
    func set(nextPackage resolvedAction: ResolvedAction) {
        DispatchQueue.main.async {
            let label: String
            
            switch resolvedAction.actionType {
            case .install:
                label = Strings.installingPackage(name: resolvedAction.nativeName, version: resolvedAction.version)
            case .uninstall:
                label = Strings.uninstallingPackage(name: resolvedAction.nativeName, version: resolvedAction.version)
            }
            
            self.contentView.horizontalIndicator.increment(by: 1.0)
            self.contentView.nameLabel.stringValue = label
            self.setRemaining()
        }
    }

    func set(totalPackages total: Int) {
        contentView.horizontalIndicator.maxValue = Double(total)
        
        if (total == 1) {
            contentView.horizontalIndicator.isIndeterminate = true
            contentView.horizontalIndicator.startAnimation(self)
        }
    }
    
    func handle(error: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: Strings.ok)
        alert.messageText = Strings.errorDuringInstallation
        alert.informativeText = error
        
        log.error(error)
        alert.runModal()
        
        AppContext.windows.set(MainViewController(), for: MainWindowController.self)
    }
    
    func beginCancellation() {
        contentView.primaryButton.isEnabled = false
        contentView.primaryButton.title = Strings.cancelling
    }
    
    func processCancelled() {
        AppContext.windows.set(MainViewController(), for: MainWindowController.self)
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "button":
            contentView.primaryButton.title = Strings.cancel
            contentView.primaryButton.sizeToFit()
            return NSToolbarItem(view: contentView.primaryButton, identifier: itemIdentifier)
        case "title":
            contentView.primaryLabel.stringValue = Strings.installingUninstalling
            contentView.primaryLabel.sizeToFit()
            return NSToolbarItem(view: contentView.primaryLabel, identifier: itemIdentifier)
        default:
            return nil
        }
    }
    
    private func configureToolbar() {
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        
        window.titleVisibility = .hidden
        window.toolbar!.isVisible = true
        window.toolbar!.delegate = self
        
        let toolbarItems = [NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "title",
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "button"]
        
        window.toolbar!.setItems(toolbarItems)
    }

}
