import Cocoa

class MainWindow: Window {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleButton: NSButton!
}

class MainWindowController: WindowController<MainWindow> {
}
