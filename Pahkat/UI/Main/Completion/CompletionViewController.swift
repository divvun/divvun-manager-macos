import Foundation
import RxSwift
import RxCocoa

class CompletionViewController: DisposableViewController<CompletionView>, CompletionViewable {
    var onRestartButtonTapped: Observable<Void> = Observable.empty()
    var onFinishButtonTapped: Observable<Void> = Observable.empty()
    
    private var requiresReboot: Bool = true
    
    required init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func rebootSystem() {
        let source = "tell application \"Finder\"\nrestart\nend tell"
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        window.titleVisibility = .visible
        window.toolbar!.isVisible = false
        
        title = Strings.processCompletedTitle
        
        if (self.requiresReboot) {
            contentView.headerLabel.stringValue = Strings.restartRequiredTitle
            contentView.contentLabel.stringValue = Strings.restartRequiredBody
            
            contentView.leftButton.title = Strings.restartLater
            contentView.rightButton.title = Strings.restartNow
            contentView.leftButton.sizeToFit()
            contentView.rightButton.sizeToFit()
            contentView.leftButton.isHidden = false
            
            contentView.leftButton.rx.tap.subscribe(onNext: { [weak self] _ in
                AppContext.currentTransaction.onNext(.notStarted)
            }).disposed(by: bag)
            
            contentView.rightButton.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.rebootSystem()
            }).disposed(by: bag)
            
        } else {
            contentView.headerLabel.stringValue = Strings.processCompletedTitle
            contentView.contentLabel.stringValue = Strings.processCompletedBody
            
            contentView.rightButton.title = Strings.finish
            contentView.rightButton.sizeToFit()
            contentView.leftButton.isHidden = true
            
            contentView.rightButton.rx.tap.subscribe(onNext: { [weak self] _ in
                AppContext.currentTransaction.onNext(.notStarted)
            }).disposed(by: bag)
        }
    }
}
