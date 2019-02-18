//
//  SelfUpdateClient.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-02-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Cocoa

class SelfUpdateClient {
    let client: PahkatClient
    let overrideUpdateChannel: Bool
    let package: Package
    let status: PackageStatusResponse
    
    init?() {
        guard let tmplSelfUpdatePath = Bundle.main.url(forResource: "selfupdate", withExtension: "json") else {
            log.debug("No selfupdate.json found in bundle.")
            return nil
        }
        
        let tmpDir = URL(string: "file:///tmp/pahkat-\(NSUserName())-\(Date().timeIntervalSince1970)/")!
        let selfUpdatePath = tmpDir.appendingPathComponent("selfupdate.json")
        
        do {
            try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: false, attributes: nil)
            try FileManager.default.copyItem(at: tmplSelfUpdatePath, to: selfUpdatePath)
        } catch {
            log.severe(error)
            return nil
        }
        
        guard let client = PahkatClient(configPath: selfUpdatePath.path) else {
            log.debug("No PahkatClient generated for given config.")
            return nil
        }
        
        guard let repo = client.repos().first else {
            log.debug("No repo found in config.")
            return nil
        }
        
        client.config.set(cachePath: tmpDir.path)
        
        var overrideUpdateChannel = false
        if let selfUpdateChannelString = AppContext.client.config.get(uiSetting: "selfUpdateChannel") {
            if let selfUpdateChannel = Repository.Channels.init(rawValue: selfUpdateChannelString) {
                client.config.set(repos: [RepoConfig(url: client.config.repos()[0].url, channel: selfUpdateChannel)])
                client.refreshRepos()
                overrideUpdateChannel = true
            }
        }
        
        guard let package = repo.packages["divvun-installer-macos"], let status = repo.status(forPackage: package) else {
            log.debug("No self update package found!")
            return nil
        }
        
        self.overrideUpdateChannel = overrideUpdateChannel
        self.client = client
        self.package = package
        self.status = status
    }
    
    func assertSuccessfulUpdate() -> Bool {
        guard let v = AppContext.client.config.get(uiSetting: "no.divvun.Pahkat.updatingTo") else { return true }
        
        if v != package.version {
            let alert = NSAlert()
            alert.messageText = "Update Failed"
            alert.informativeText = "It seems that the previous update attempt failed. If problems persist, please download the installer directly from the website."
            
            alert.alertStyle = .warning
            alert.addButton(withTitle: Strings.ok)
            alert.addButton(withTitle: "Download from Divvun")
            
            if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
                let url = URL(string: "http://divvun.no/korrektur/oswide.html")!
                NSWorkspace.shared.open(url)
            }
        }
        
        AppContext.client.config.set(uiSetting: "no.divvun.Pahkat.updatingTo", value: nil)
        return true
    }
    
    func checkForSelfUpdate() -> Bool {
        log.debug("Found divvun-installer-macos version: \(package.version) \(status)")
        
        switch status.status {
        case .notInstalled:
            log.debug("Selfupdate: self not installed, likely debugging.")
        case .versionSkipped:
            log.debug("Selfupdate: self is blocked from updating itself")
        case .requiresUpdate:
            if overrideUpdateChannel {
                let alert = NSAlert()
                alert.messageText = "Beta Update Available"
                alert.informativeText = "You are using a developer mode channel override. Would you like to update to the latest beta?"
                
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Don't Install")
                alert.addButton(withTitle: "Install")
                
                if alert.runModal() != NSApplication.ModalResponse.alertSecondButtonReturn {
                    return false
                }
            }
            return true
        default:
            break
        }
        
        return false
    }
}


