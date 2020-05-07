import Cocoa
import WebKit

class LandingView: View {
    @IBOutlet weak var primaryLabel: NSTextField!
    @IBOutlet weak var primaryButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    @IBOutlet weak var messageLabel: NSTextField!

    var webView: WKWebView!

    enum State {
        case empty
        case normal
    }
    
    override func awakeFromNib() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), configuration: config)
        self.autoresizesSubviews = true
        webView.autoresizingMask = [.height, .width]
        self.addSubview(webView)
        
        primaryLabel.stringValue = Strings.appName
        primaryButton.title = "Detailed…"
        messageLabel.stringValue = "To get started, add a repository in Settings."
        messageLabel.isHidden = true
    }

    func updateView(state: State) {
        webView.isHidden = state == .empty
        messageLabel.isHidden = state == .normal
    }
}

