import Cocoa
import RxSwift
import RxCocoa

class MainView: View {
    @IBOutlet var primaryLabel: NSTextField!
    @IBOutlet var primaryButton: NSButton!
    @IBOutlet var settingsButton: NSButton!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    var popupButton = NSPopUpButton(title: Strings.selectRepository, target: nil, action: nil)
    
    override func awakeFromNib() {
        primaryButton.title = Strings.noPackagesSelected
        primaryLabel.stringValue = Strings.appName
        popupButton.autoenablesItems = true

        progressIndicator.startAnimation(self)
    }
}


