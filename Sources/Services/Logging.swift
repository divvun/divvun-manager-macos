//
//  Logging.swift
//  Divvun Manager
//
//  Created by Brendan Molloy on 2020-09-14.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation
import XCGLogger

private let userLibraryDir = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
private let divvunManagerLogsPath = userLibraryDir
    .appendingPathComponent("Logs")
    .appendingPathComponent("Divvun Manager")

private let systemDest: AppleSystemLogDestination = {
    let x = AppleSystemLogDestination(identifier: "DivvunManager.system")
    x.outputLevel = .debug
    return x
}()

private let fileDest: AutoRotatingFileDestination = {
    let x = AutoRotatingFileDestination(
        writeToFile: divvunManagerLogsPath.appendingPathComponent("app.log").path,
        identifier: "DivvunManager.file")
    x.outputLevel = .debug
    x.logQueue = XCGLogger.logQueue
    return x
}()

internal let log: XCGLogger = {
    let x = XCGLogger(identifier: "DivvunManager", includeDefaultDestinations: false)

    try? FileManager.default.createDirectory(at: divvunManagerLogsPath,
                                        withIntermediateDirectories: true,
                                        attributes: nil)

    x.add(destination: systemDest)
    x.add(destination: fileDest)
    x.logAppDetails()

    return x
}()
