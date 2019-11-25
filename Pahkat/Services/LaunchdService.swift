//
//  LaunchdService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

class LaunchdService {
    static let plistName = "\(Bundle.main.bundleIdentifier!).PahkatUpdateAgent"
    static let restartPlistName = "\(Bundle.main.bundleIdentifier!).PahkatRestartAgent"
    static let agentHelper = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/PahkatUpdateAgent").path
    
    static let userLaunchAgentsPath: URL = {
        let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        return URL(string: "file://\(libraryDirectory)/LaunchAgents/")!
    }()
    
    static let plistUserPath: URL = {
        return LaunchdService.userLaunchAgentsPath.appendingPathComponent("\(plistName).plist")
    }()
    static let restartPlistUserPath: URL = {
        return LaunchdService.userLaunchAgentsPath.appendingPathComponent("\(restartPlistName).plist")
    }()
    
    static func generateLaunchAgent(startInterval: Int) -> NSDictionary {
        // Cry deeply for the plist lifestyle
        let plist = NSMutableDictionary()
        plist.setValue(plistName, forKey: "Label")
        plist.setValue(agentHelper, forKey: "Program")
        plist.setValue(startInterval, forKey: "StartInterval")
        return plist
    }
    
    static func generateRestartLaunchAgent() -> NSDictionary {
        let plist = NSMutableDictionary()
        plist.setValue(restartPlistName, forKey: "Label")
        plist.setValue(agentHelper, forKey: "Program")
        plist.setValue(["restart-app"], forKey: "ProgramArguments")
        plist.setValue(false, forKey: "RunAtLoad")
        plist.setValue("/tmp/pahkat_restart.log", forKey: "StandardOutPath")
        plist.setValue("/tmp/pahkat_restart_err.log", forKey: "StandardErrorPath")
        return plist
    }
    
    static func writeLaunchAgent(_ agent: NSDictionary, path: URL) -> Bool {
        try? FileManager.default.createDirectory(at: LaunchdService.userLaunchAgentsPath, withIntermediateDirectories: true, attributes: nil)
        return agent.write(to: path, atomically: true)
    }
    
    static func hasLaunchAgent() -> Bool {
        return FileManager.default.fileExists(atPath: plistUserPath.path)
    }
    
    private static func launchctl(_ arguments: [String]) throws {
        try Process.run(URL(string: "/bin/launchctl")!, arguments: arguments, terminationHandler: nil).waitUntilExit()
    }
    
    static func unload() throws {
        try launchctl(["unload", plistUserPath.path])
    }
    
    static func load() throws {
        try launchctl(["load", plistUserPath.path])
    }
    
    static func restartApp() -> Bool {
//        let plist = generateRestartLaunchAgent()
//        if !writeLaunchAgent(plist, path: restartPlistUserPath) {
//            return false
//        }
//        
//        try? launchctl(["unload", restartPlistUserPath.path])
//        try? launchctl(["load", restartPlistUserPath.path])
//
//        DispatchQueue.global(qos: .background).async {
//            try! launchctl(["start", restartPlistName])
//        }
        
        return true
    }
    
    static func removeLaunchAgent() throws {
        if hasLaunchAgent() {
            try unload()
            try FileManager.default.removeItem(at: plistUserPath)
        }
    }
    
    static func saveNewLaunchAgent(startInterval: Int) throws -> Bool {
        if hasLaunchAgent() {
            try unload()
        }
        
        let plist = generateLaunchAgent(startInterval: startInterval)
        if !writeLaunchAgent(plist, path: plistUserPath) {
            return false
        }
        
        try load()
        return true
    }
    
    private init() {}
}
