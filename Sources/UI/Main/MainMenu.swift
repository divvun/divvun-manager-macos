import Foundation
import Cocoa

class MainMenu: NSMenu {
    @IBOutlet weak var prefsMenuItem: NSMenuItem!
    @IBOutlet weak var genDebugZipFileItem: NSMenuItem!

    @objc func onClickGenerateDebugZipFile(_ sender: NSObject) {
        let alert = NSAlert()
        alert.informativeText = "This function creates a zip file containing logging information useful " +
            "for assisting debugging issues with Divvun Installer and its packages.\n\n" +
            "This tool should only be used when requested by your IT administrator or Divvun personnel."
        alert.messageText = "Create debugging zip file"
        alert.addButton(withTitle: "Save Debug Zip")
        alert.addButton(withTitle: Strings.cancel)
        if alert.runModal() != .alertFirstButtonReturn {
            return
        }

        let savePanel = NSSavePanel()

        savePanel.nameFieldStringValue = "divvun-manager-debug.zip"
        savePanel.allowedFileTypes = ["zip"]
        savePanel.allowsOtherFileTypes = false
        savePanel.prompt = "Save"

        let desktopDir = try? FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        savePanel.directoryURL = desktopDir

        let response = savePanel.runModal()

        if response == .OK {
            do {
                try LogCollator.save(path: savePanel.url!.path)
            } catch let error {
                print(error)
            }
        }

        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("feedback@divvun.no", forType: .string)

        let alert2 = NSAlert()
        alert2.informativeText = "A zip file named \(savePanel.url!.lastPathComponent) has been created.\n\n" +
            "Please attach this to an email to feedback@divvun.no.\n\n" +
            "(The email address has been automatically copied to your clipboard " +
            "for your convenience. You can paste this into your email program or web-based " +
            "email tool)"
        alert2.messageText = "Debug Data Zipped!"
        alert2.addButton(withTitle: "Go to file")

        if alert2.runModal() == .alertFirstButtonReturn {
            let proc = Process()
            proc.launchPath = "/usr/bin/open"
            proc.arguments = ["-R", savePanel.url!.path]
            proc.launch()
        }
    }

    @objc func onClickMainMenuPreferences(_ sender: NSObject) {
        AppContext.windows.show(SettingsWindowController.self)
    }
    
    override func awakeFromNib() {
//        log.debug("Awakening menu item from nib")
        
        for item in self.allItems() {
//            log.debug(item)
            
            if let item = item as? CompatNSMenuItem {
                let id = item.stringKey
//                log.debug(id)
                if id != "" {
                    let s = Strings.string(for: id)
                    if s != id {
                        item.title = s
                    }
                }
            }
        }
        
        prefsMenuItem.target = self
        prefsMenuItem.action = #selector(MainMenu.onClickMainMenuPreferences(_:))

        genDebugZipFileItem.target = self
        genDebugZipFileItem.action = #selector(MainMenu.onClickGenerateDebugZipFile(_:))
    }
}

extension NSMenu {
    func allItems() -> [NSMenuItem] {
        var out = self.items
        
        for item in self.items {
            if let menu = item.submenu {
                out.append(contentsOf: menu.allItems())
            }
        }
        
        return out
    }
}
