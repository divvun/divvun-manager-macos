//
//  Logging.swift
//  Divvun Manager
//
//  Created by Brendan Molloy on 2020-09-14.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation
import XCGLogger

let userLibraryDir = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
let divvunManagerLogsPath = userLibraryDir
    .appendingPathComponent("Logs")
    .appendingPathComponent("Divvun Manager")

let systemDest: AppleSystemLogDestination = {
    let x = AppleSystemLogDestination(identifier: "DivvunManager.system")
    x.outputLevel = .debug
    return x
}()

let fileDest: AutoRotatingFileDestination = {
    let x = AutoRotatingFileDestination(
        writeToFile: divvunManagerLogsPath.appendingPathComponent("app.log").path,
        identifier: "DivvunManager.file")
    x.logQueue = XCGLogger.logQueue
    return x
}()

internal let log: XCGLogger = {
    let x = XCGLogger(identifier: "DivvunManager", includeDefaultDestinations: false)

    x.add(destination: systemDest)
    x.add(destination: fileDest)
    x.logAppDetails()

    return x
}()
