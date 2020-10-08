import Cocoa
import RxSwift
import RxCocoa

struct RepositoryTableRowData {
    let url: URL
    let repo: LoadedRepository?
    let channel: String?
}

class SettingsViewController: DisposableViewController<SettingsView>, SettingsViewable, NSWindowDelegate {
    private(set) var tableDelegate: RepositoryTableDelegate! = nil

    var onAddRepoButtonTapped: Driver<Void> {
        return contentView.repoAddButton.rx.tap.asDriver()
    }
    
    var onRemoveRepoButtonTapped: Driver<Void> {
        return contentView.repoRemoveButton.rx.tap.asDriver()
    }

    // FIXME: this gets the width as wide as I need it... lol
    let textField = NSTextField(string: "                                                                       ")

    func addBlankRepositoryRow() {
        let alert = NSAlert()

        alert.accessoryView = textField
        textField.stringValue = ""
        textField.placeholderString = "https://…"

        alert.addButton(withTitle: Strings.save)
        alert.addButton(withTitle: Strings.cancel)
        alert.messageText = "Add Repository"
        alert.informativeText = "Enter the URL for the repository to add:"

        alert.alertStyle = .informational

        alert.beginSheetModal(
            for: AppContext.windows.get(SettingsWindowController.self).window!,
            completionHandler: { response in
                guard let url = URL(string: self.textField.stringValue) else {
                    log.error("Not a valid URL.")
                    return
                }

                self.addRepo(url: url)
            })
    }
    
    func updateProgressIndicator(isEnabled: Bool) {
        DispatchQueue.main.async {
            if isEnabled {
                self.contentView.repoTableView.isHidden = true
                self.contentView.progressIndicator.startAnimation(self)
            } else {
                self.contentView.repoTableView.isHidden = false
                self.contentView.progressIndicator.stopAnimation(self)
            }
        }
    }

    private func addRepo(url: URL) {
        AppContext.packageStore.setRepo(url: url, record: RepoRecord(channel: nil))
            .subscribe(onSuccess: { [weak self] repos in
                self?.refreshRepoTable()
            })
            .disposed(by: self.bag)
    }
    
    func promptRemoveRepositoryRow() {
        let row = self.contentView.repoTableView.selectedRow
        if row < 0 {
            return
        }
        let alert = NSAlert()
        alert.messageText = Strings.removeRepoTitle
        alert.informativeText = Strings.removeRepoBody
        alert.addButton(withTitle: Strings.ok)
        alert.addButton(withTitle: Strings.cancel)

        alert.beginSheetModal(for: self.contentView.window!, completionHandler: {
            if $0 == NSApplication.ModalResponse.alertFirstButtonReturn {
                AppContext.packageStore.removeRepo(url: self.tableDelegate.configs[row].url)
                    .subscribe()
                    .disposed(by: self.bag)

                self.tableDelegate.configs.remove(at: row)
                self.contentView.repoTableView.beginUpdates()
                self.contentView.repoTableView.removeRows(at: IndexSet(integer: row), withAnimation: .effectFade)
                self.contentView.repoTableView.endUpdates()

                self.refreshRepoTable()
            }
        })
    }
    
    func handle(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = error.localizedDescription
            
            alert.alertStyle = .critical
            log.error(error)
            alert.runModal()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppContext.windows.get(SettingsWindowController.self).window!.delegate = self
        
        title = Strings.settings
        
        InterfaceLanguage.bind(to: contentView.languageDropdown.menu!)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        contentView.repoAddButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.addBlankRepositoryRow()
        }).disposed(by: bag)
        
        contentView.repoRemoveButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.promptRemoveRepositoryRow()
        }).disposed(by: bag)

        if let language: String = AppContext.settings.read(key: .language) {
            if let item = self.contentView.languageDropdown.menu!.items
                .first(where: { ($0.representedObject as! InterfaceLanguage).rawValue == language })
            {
                self.contentView.languageDropdown.select(item)
            }
        } else {
            self.contentView.languageDropdown.selectItem(at: 0)
        }

        contentView.languageDropdown.rx.tap
            .map { self.contentView.languageDropdown.selectedItem!.representedObject as! InterfaceLanguage }
            .subscribe(onNext: { v in
                try? AppContext.settings.write(key: .language, value: v.rawValue)
                if v == .systemLocale {
                    UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                } else {
                    UserDefaults.standard.set([v.rawValue], forKey: "AppleLanguages")
                }
            }).disposed(by: bag)

        updateProgressIndicator(isEnabled: true)

        self.tableDelegate = RepositoryTableDelegate(with: [], strings: [:])
        contentView.repoTableView.delegate = self.tableDelegate
        contentView.repoTableView.dataSource = self.tableDelegate

        tableDelegate.events.subscribe(onNext: { event in
            switch event {
            case let .setChannel(row):
                return AppContext.packageStore.setRepo(url: row.url, record: RepoRecord(channel: row.channel))
                    .subscribe()
                    .disposed(by: self.bag)
            }
        }).disposed(by: bag)

        // Add all the info to the table
        refreshRepoTable()
    }

    func refreshRepoTable() {
        Single.zip(
                AppContext.packageStore.repoIndexes(),
                AppContext.packageStore.getRepoRecords(),
                AppContext.packageStore.strings(languageTag: Strings.languageCode)
            )
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (repos, records, strings) in
                let rows = records.map { (key, value) in
                    return RepositoryTableRowData(url: key, repo: repos.first(where: { $0.index.url == key }), channel: value.channel)
                }

                self?.setRepositories(repositories: rows, strings: strings)
                self?.updateProgressIndicator(isEnabled: false)
            }, onError: { [weak self] error in
                self?.handle(error: error)
            }).disposed(by: bag)
    }
    
    func setRepositories(repositories: [RepositoryTableRowData], strings: [URL: MessageMap]) {
        self.tableDelegate.configs = repositories
        self.tableDelegate.strings = strings
        self.contentView.repoTableView.reloadData()
    }
}

enum RepositoryTableColumns: String {
    case name
    case channel
    
    init?(identifier: NSUserInterfaceItemIdentifier) {
        if let value = RepositoryTableColumns(rawValue: identifier.rawValue) {
            self = value
        } else {
            return nil
        }
    }
}

enum RepositoryTableEvent {
    case setChannel(RepositoryTableRowData)
}

class RepositoryTableDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    fileprivate var configs: [RepositoryTableRowData]
    fileprivate var strings: [URL: MessageMap] = [:]
    fileprivate let events = PublishSubject<RepositoryTableEvent>()
    
    init(with configs: [RepositoryTableRowData], strings: [URL: MessageMap]) {
        self.configs = configs
        self.strings = strings
        super.init()
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let tableColumn = tableColumn else { return nil }
        guard let column = RepositoryTableColumns(identifier: tableColumn.identifier) else { return nil }
        
        if row >= configs.count {
            return nil
        }
        
        let config = configs[row]
        
        switch column {
        case .name:
            if let repo = config.repo {
                return repo.index.nativeName
            } else {
                return "\(config.url.absoluteString) ⚠️"
            }
        case .channel:
            guard let cell = tableColumn.dataCell as? NSPopUpButtonCell else { return nil }

            let url = configs[row].url
            let s = strings[url]?.channels ?? [String: String]()

            var channels: [(String, String)]
            if let repo = configs[row].repo {
                channels = repo.index.channels.sorted().map { channelId in
                    if let channel = s[channelId] {
                        return (channelId, channel)
                    } else {
                        return (channelId, channelId)
                    }
                }
            } else {
                channels = []
            }

            // default channel
            channels.insert(("", Strings.stable), at: 0)

            cell.removeAllItems()
            cell.addItems(withTitles: channels.map { $0.1 })
            for i in 0..<channels.count {
                cell.menu?.item(at: i)?.representedObject = channels[i].0
            }

            let ch = /*strings[url]?.channels[config.channel ?? ""] ?? */ config.channel

            guard let index = cell.menu?.items.firstIndex(where: {
                $0.representedObject as? String == ch
            }) else {
                return 0
            }

            return index
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let tableColumn = tableColumn else { return }
        guard let column = RepositoryTableColumns(identifier: tableColumn.identifier) else { return }
        
        if row >= configs.count {
            return
        }
        
        switch column {
        case .channel:
            guard let cell = tableColumn.dataCell as? NSPopUpButtonCell else { return }
            guard let index = object as? Int else { return }
            guard let menuItem = cell.menu?.item(at: index) else { return }
            guard let channel = menuItem.representedObject as? String? else { return }
            
            // Required or UI does a weird blinking thing.
            self.configs[row] = RepositoryTableRowData(url: configs[row].url, repo: configs[row].repo, channel: channel)
            events.onNext(.setChannel(configs[row]))
        default:
            return
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.configs.count
    }
}
