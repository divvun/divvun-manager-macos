import Cocoa
import WebKit

extension NSView {
    func bringSubviewToFront(_ view: NSView) {
        var theView = view
        self.sortSubviews({ (viewA, viewB, rawPointer) in
            let view = rawPointer?.load(as: NSView.self)

            switch view {
            case viewA:
                return ComparisonResult.orderedDescending
            case viewB:
                return ComparisonResult.orderedAscending
            default:
                return ComparisonResult.orderedSame
            }
        }, context: &theView)
    }
}


class LandingView: View {
    @IBOutlet weak var primaryLabel: NSTextField!
    @IBOutlet weak var primaryButton: NSButton!
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var openSettingsButton: NSButton!
    @IBOutlet weak var resetToDefaultsButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    var popupButton = NSPopUpButton(title: Strings.selectRepository, target: nil, action: nil)

    var webView: WKWebView!

    enum State {
        case empty
        case normal
    }

    private var firstLoad = true
    
    override func awakeFromNib() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), configuration: config)
        self.autoresizesSubviews = true
        webView.autoresizingMask = [.height, .width]
        self.addSubview(webView)
        self.bringSubviewToFront(progressIndicator)
        progressIndicator.startAnimation(self)
        popupButton.autoenablesItems = true
        
        primaryLabel.stringValue = Strings.appName
        messageLabel.stringValue = Strings.toGetStartedAddARepoInSettings
        openSettingsButton.title = Strings.openSettings
        resetToDefaultsButton.title = "Reset to Defaults"
    }

    func updateView(state: State) {
        assert(Thread.isMainThread)
        webView.isHidden = state == .empty
        if firstLoad {
            progressIndicator.isHidden = state != .normal
            firstLoad = false
        }
        messageLabel.isHidden = state == .normal
        openSettingsButton.isHidden = state == .normal
        resetToDefaultsButton.isHidden = state == .normal
    }
}

