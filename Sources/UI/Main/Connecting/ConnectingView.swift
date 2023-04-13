import Cocoa
import WebKit

class ConnectingView: View {
    @IBOutlet weak var primaryLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    enum State {
        case normal
        case tooLong
        case wayTooLong
    }

    override func awakeFromNib() {
        progressIndicator.startAnimation(self)
        updateView(state: .normal)
    }

    func updateView(state: State) {
        assert(Thread.isMainThread)
        switch state {
        case .normal:
            primaryLabel.stringValue = Strings.connecting
        case .tooLong:
            primaryLabel.stringValue = Strings.takingTooLong
        case .wayTooLong:
            primaryLabel.stringValue = Strings.connectionFailed
            progressIndicator.isHidden = true
        }
    }
}

