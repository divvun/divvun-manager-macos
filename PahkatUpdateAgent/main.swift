////
////  main.swift
////  agenthelper
////
////  Created by Brendan Molloy on 2018-03-04.
////  Copyright © 2018 Divvun. All rights reserved.
////

import Foundation
import Cocoa
import RxSwift

func pahkatEvent(eventID: PahkatAppleEvent) -> NSAppleEventDescriptor {
    return NSAppleEventDescriptor.appleEvent(withEventClass: PahkatAppleEvent.classID,
                                             eventID: eventID.rawValue,
                                             targetDescriptor: nil,
                                             returnID: Int16(kAutoGenerateReturnID),
                                             transactionID: Int32(kAnyTransactionID))
}

func launchConfig(eventID: PahkatAppleEvent) -> [NSWorkspace.LaunchConfigurationKey: Any] {
    return [
        NSWorkspace.LaunchConfigurationKey.appleEvent: pahkatEvent(eventID: eventID),
        NSWorkspace.LaunchConfigurationKey.arguments: [eventID.stringValue]
    ]
}

func openAppWith(event: PahkatAppleEvent) {
    try! NSWorkspace.shared.launchApplication(at: Bundle.main.bundleURL, options: .default, configuration: launchConfig(eventID: event))
}

func checkForUpdates() {
    let client = PahkatClient()!
    
    let hasUpdates = client.repos().contains(where: {
        return $0.statuses.contains(where: {
            return $0.1.status == .requiresUpdate
        })
    })
    
    if hasUpdates {
        print("Updates found!")
        openAppWith(event: .update)
    } else {
        print("No updates found.")
    }
    
    exit(0)
}

func restartApp() {
    let exe = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/Pahkat")

    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.executableURL == exe }) {
        app.forceTerminate()
    }

    openAppWith(event: .restartApp)
    exit(0)
}

print(Bundle.main)
print(CommandLine.arguments)

if CommandLine.argc > 1 {
    switch CommandLine.arguments[1] {
    case "restart-app":
        restartApp()
    default:
        checkForUpdates()
    }
} else {
    checkForUpdates()
}
