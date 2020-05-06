import Cocoa

class SettingsView: View {
    @IBOutlet weak var languageDropdown: NSPopUpButton!
    @IBOutlet weak var languageLabel: NSTextField!
    @IBOutlet weak var languageHelpLabel: NSTextField!
    
    @IBOutlet weak var repoTableView: NSTableView!
    @IBOutlet weak var repoLabel: NSTextField!
    
    @IBOutlet weak var repoAddButton: NSButton!
    @IBOutlet weak var repoRemoveButton: NSButton!
    
    @IBOutlet weak var repoChannelColumn: NSPopUpButtonCell!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func awakeFromNib() {
        languageLabel.stringValue = "\(Strings.interfaceLanguage):"
        languageHelpLabel.stringValue = Strings.restartTheAppForLanguageChanges
        repoLabel.stringValue = "\(Strings.repositories):"
        
        for column in repoTableView.tableColumns {
            let id = column.identifier.rawValue
            column.headerCell.stringValue = Strings.string(for: id)
        }
        
        self.repoTableView.headerView?.needsLayout = true
        
        repoChannelColumn.menu = NSMenu()
    }
}
