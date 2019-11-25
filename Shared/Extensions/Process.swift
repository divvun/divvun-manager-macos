//
//  Process.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation

extension Process {
    @discardableResult
    static func run(_ url: URL, arguments: [String], terminationHandler: ((Process) -> Swift.Void)? = nil) throws -> Process {
        let process = Process()
        process.launchPath = url.path
        process.arguments = arguments
        process.terminationHandler = terminationHandler
        process.launch()
        return process
    }
}
