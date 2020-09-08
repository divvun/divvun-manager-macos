import Cocoa
import RxSwift
import RxCocoa

class InstallView: View {
    @IBOutlet weak var spinningIndicator: NSProgressIndicator!
    @IBOutlet weak var horizontalIndicator: NSProgressIndicator!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var remainingLabel: NSTextField!
    
    @IBOutlet var primaryLabel: NSTextField!
    @IBOutlet var primaryButton: NSButton!
    
    override func awakeFromNib() {
        horizontalIndicator.controlTint = .blueControlTint
        
        spinningIndicator.isIndeterminate = true
        spinningIndicator.usesThreadedAnimation = true
        spinningIndicator.startAnimation(nil)
    }
}
