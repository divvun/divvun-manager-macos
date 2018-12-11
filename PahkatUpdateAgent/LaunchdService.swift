//
//  LaunchdService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

class LaunchdService {
    static let plistName = "\(Bundle.main.bundleIdentifier!).PahkatUpdateAgent.plist"
    static let agentHelper = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/PahkatUpdateAgent").path
    static let plistUserPath: URL = {
        let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        return URL(string: "file://\(libraryDirectory)/LaunchAgents/\(plistName)")!
    }()
    
    static func generateLaunchAgent(startInterval: Int) -> NSDictionary {
        // Cry deeply for the plist lifestyle
        let plist = NSMutableDictionary()
        plist.setValue(plistName, forKey: "Label")
        plist.setValue(agentHelper, forKey: "Program")
        plist.setValue(startInterval, forKey: "StartInterval")
        return plist
    }
    
    static func writeLaunchAgent(_ agent: NSDictionary) -> Bool {
        return agent.write(to: plistUserPath, atomically: true)
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
        if !writeLaunchAgent(plist) {
            return false
        }
        
        try load()
        return true
    }
    
    private init() {}
}
