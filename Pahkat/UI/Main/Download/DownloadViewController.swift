import Cocoa
import RxSwift
import RxCocoa

class DownloadViewController: DisposableViewController<DownloadView>, DownloadViewable, NSToolbarDelegate {
    private let byteCountFormatter = ByteCountFormatter()
    private var delegate: DownloadProgressTableDelegate! = nil

    required init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let _ = AppContext.currentTransaction
            .take(1)
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                switch state {
                case let .inProgress(progress):
                    self?.initializeDownloads(actions: progress.actions)
                default:
                    break
                }
            })
     
        AppContext.currentTransaction
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .filter { $0.isInProgress }
            .map { (state: TransactionState) -> TransactionProgressState in
                switch state {
                case .inProgress(let x):
                    return x
                default:
                    fatalError("logic error")
                }
            }
            .subscribe(onNext: { [weak self] state in
                guard let `self` = self else { return }
                
                switch state.state {
                case let .downloading(downloadState):
                    for (key, value) in downloadState {
                        self.setStatus(key: key, status: value)
                    }
                default:
                    break
                }
            }).disposed(by: bag)
//            switch state {
//            case let .inProgress(resolvedActions, isRebootRequired, processState):
//                switch processState {
//                case let .downloading(state: downloadState):
//                    let keys = resolvedActions.map{ $0.action.key }
//                    keys.forEach { key in
//                        if let progress = downloadState[key] {
//                            self.view.setStatus(key: key, status: .progress(downloaded: progress.0, total: progress.1))
//                        }
//                    }
//                    break
//                default:
//                    break
//                }
//            default:
//                break
//            }
//        presenter.start().disposed(by: bag)
    }
    
    var onCancelTapped: Driver<Void> {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }
    
    // TODO: maybe get rid of PackageDownloadStatus and use the new RPC one?
    func setStatus(key: PackageKey?, status: DownloadProgress) {
        guard let key = key else {
            // we need a key yo
            return
        }
            
        
        DispatchQueue.main.async {
            if let view = self.delegate.tableView(self.contentView.tableView, viewFor: key) as? DownloadProgressView {
                let current = status.current
                let total = status.total
                
                // just starting is 0, 0
                switch (current, total) {
                case (0, 0):
                    view.progressLabel.stringValue = Strings.starting
                case (UInt64.max, UInt64.max):
                    view.progressLabel.stringValue = Strings.downloadError
                case let (x, y) where x == y:
                    view.updateProgressBar(current: x, total: y)
                    view.progressLabel.stringValue = Strings.completed
                case let (x, y):
                    view.updateProgressBar(current: x, total: y)

                    let downloadStr = self.byteCountFormatter.string(fromByteCount: Int64(x))
                    let totalStr = self.byteCountFormatter.string(fromByteCount: Int64(y))

                    view.progressLabel.stringValue = "\(downloadStr) / \(totalStr)"
                }
                
//                switch(status) {
////                case .notStarted:
////                    view.progressLabel.stringValue = Strings.queued
//                case .starting:
//                    view.progressLabel.stringValue = Strings.starting
//                    if let cellOrigin: NSPoint = view.superview?.frame.origin {
//                        self.contentView.clipView.animate(to: cellOrigin, with: 0.5)
//                    }
//                case .progress(let downloaded, let total):
//                    view.progressBar.maxValue = Double(total)
//                    view.progressBar.minValue = 0
//                    view.progressBar.doubleValue = Double(downloaded)
//
//                    let downloadStr = self.byteCountFormatter.string(fromByteCount: Int64(downloaded))
//                    let totalStr = self.byteCountFormatter.string(fromByteCount: Int64(total))
//
//                    view.progressLabel.stringValue = "\(downloadStr) / \(totalStr)"
//                case .completed:
//                    view.progressLabel.stringValue = Strings.completed
//                case .error:
//                    view.progressLabel.stringValue = Strings.downloadError
//                case .
//                }
            } else {
                fatalError("couldn't get downloadProgressView")
            }
        }
    }

    func cancel() {
        
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "button":
            contentView.primaryButton.title = Strings.cancel
            contentView.primaryButton.sizeToFit()
            return NSToolbarItem(view: contentView.primaryButton, identifier: itemIdentifier)
        case "title":
            contentView.primaryLabel.stringValue = Strings.downloading
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
    
    override func viewDidLoad() {
        title = Strings.downloading
        
        configureToolbar()
    }
    
    func initializeDownloads(actions: [ResolvedAction]) {
        self.delegate = DownloadProgressTableDelegate(with: actions)
        contentView.tableView.delegate = self.delegate
        contentView.tableView.dataSource = self.delegate
    }
}

class DownloadProgressTableDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private var views = [View]()
    private let actions: [ResolvedAction]
    
    init(with actions: [ResolvedAction]) {
        self.actions = actions
        
        for action in actions {
            let view = DownloadProgressView.loadFromNib()
            let name = action.nativeName
            view.nameLabel.stringValue = "\(name) \(action.version)"
            self.views.append(view)
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor key: PackageKey) -> NSView? {
        if let row = actions.map({ $0.key }).firstIndex(of: key) {
            return self.tableView(tableView, viewFor: nil, row: row)
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return views[row]
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return views.count
    }
}

extension NSClipView {
    func animate(to point: NSPoint, with duration: TimeInterval) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        NSAnimationContext.current.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.default)
        self.animator().setBoundsOrigin(point)
        if let scrollView = self.superview as? NSScrollView {
            scrollView.reflectScrolledClipView(self)
        }
        NSAnimationContext.endGrouping()
    }
}
