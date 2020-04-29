import Cocoa

class SettingsWindow: Window {}

class SettingsWindowController: WindowController<SettingsWindow> {
    override func windowDidLoad() {
        DispatchQueue.main.async {
            self.viewController = SettingsViewController()
        }
    }
}
