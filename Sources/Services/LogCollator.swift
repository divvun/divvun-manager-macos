//
//  LogCollector.swift
//  Divvun Manager
//
//  Created by Brendan Molloy on 2020-10-08.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation

enum LogCollatorError: Error {
    case failedToOpenPath
}

class LogCollator {
    static func save(path: String) throws {
        let archive = SSZipArchive(path: path)

        if !archive.open() {
            throw LogCollatorError.failedToOpenPath
        }

        let collator = LogCollator(archive)

        collator.run()
    }

    private let archive: SSZipArchive
    private var runLog: [String] = []

    private init(_ archive: SSZipArchive) {
        self.archive = archive
    }

    private func run() {
        runLog.append("Beginning collation at: \(Date().iso8601)")
        collectPahkatData()
        collectMacDivvunLogs()
        collectPkgutilInfo()
        collectApplicationsDirListing()
        runLog.append("Finishing collation at: \(Date().iso8601)")

        let runLogData = runLog.joined(separator: "\n").data(using: .utf8)!
        archive.write(runLogData, filename: "run.txt", compressionLevel: 9, password: nil, aes: false)

        self.archive.close()
    }

    let systemLibraryDir = try! FileManager.default.url(for: .libraryDirectory, in: .localDomainMask, appropriateFor: nil, create: false)
    let userLibraryDir = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    private(set) lazy var systemLogsDir = { systemLibraryDir.appendingPathComponent("Logs") }()
    private(set) lazy var userLogsDir = { userLibraryDir.appendingPathComponent("Logs") }()
    private(set) lazy var systemAppSupportDir = { systemLibraryDir.appendingPathComponent("Application Support") }()

    private func collectPahkatData() {
        runLog.append("Collecting Pahkat data")
        let divvunManagerLogsPath = userLogsDir.appendingPathComponent("Divvun Manager")
        let pahkatLogsPath = systemLogsDir.appendingPathComponent("Pahkat")
        let pahkatConfigPath = systemAppSupportDir.appendingPathComponent("Pahkat").appendingPathComponent("config")

        for (id, dir) in [("logs-divvun-manager", divvunManagerLogsPath), ("logs-pahkat", pahkatLogsPath), ("config-pahkat", pahkatConfigPath)] {
            if !FileManager.default.fileExists(atPath: dir.path) {
                runLog.append("No files at \(dir); skipping")
            }
            let success = archive.writeFolder(atPath: dir.path, withFolderName: id, withPassword: nil)
            if !success  {
                runLog.append("ERROR: Could not zip \(dir)")
            }

            let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []

            for file in files {
                let success = archive.writeFile(atPath: dir.appendingPathComponent(file).path, withFileName: "\(id)/\(file)", compressionLevel: 9, password: nil, aes: false)
                if !success  {
                    runLog.append("ERROR: Could not zip \(file)")
                }

            }
        }
    }

    private func collectMacDivvunLogs() {
        runLog.append("Collecting MacDivvun logs")
        let macDivvunLogsPath = userLogsDir.appendingPathComponent("MacDivvun")
        if !FileManager.default.fileExists(atPath: macDivvunLogsPath.path) {
            runLog.append("No logs at \(macDivvunLogsPath.path); skipping")
        }

        let success = archive.writeFolder(atPath: macDivvunLogsPath.path, withFolderName: "logs-macdivvun", withPassword: nil)
        if !success  {
            runLog.append("ERROR: Could not zip \(macDivvunLogsPath.path)")
        }

        let files = (try? FileManager.default.contentsOfDirectory(atPath: macDivvunLogsPath.path)) ?? []

        for file in files {
            let success = archive.writeFile(atPath: macDivvunLogsPath.appendingPathComponent(file).path, withFileName: "logs-macdivvun/\(file)", compressionLevel: 9, password: nil, aes: false)
            if !success  {
                runLog.append("ERROR: Could not zip \(file)")
            }

        }
    }

    private func collectPkgutilInfo() {
        runLog.append("Collecting pkgutil --pkgs results")
        let proc = BufferedStringSubprocess(
            "/bin/sh",
            arguments: ["-c", "for pkg in `/usr/sbin/pkgutil --pkgs`; do /usr/sbin/pkgutil --pkg-info $pkg; echo; done"])

        proc.launch()
        proc.waitUntilExit()

        let out = "===stderr===\n\(proc.outputBuf)\n\n===stdout===\n\(proc.progressBuf)"

        let success = archive.write(out.data(using: .utf8)!, filename: "pkgutil-pkgs.txt", compressionLevel: 9, password: nil, aes: false)
        if !success  {
            runLog.append("ERROR: Could not zip pkgutil-pkgs.txt")
        }

        if proc.exitCode != 0 {
            runLog.append("ERROR: pkgutil failed with exit code: \(proc.exitCode)")
        }
    }

    private func collectApplicationsDirListing() {
        do {
            let paths = try FileManager.default.contentsOfDirectory(atPath: "/Applications")
            let pathsString = paths.joined(separator: "\n")
            let success = archive.write(pathsString.data(using: .utf8)!, filename: "applications.txt", compressionLevel: 9, password: nil, aes: false)
            if !success  {
                runLog.append("ERROR: Could not zip applications.txt")
            }
        } catch let error {
            runLog.append("ERROR: failed to get directory contents of /Application: \(error)")
        }
    }
}

class BufferedStringSubprocess {
    private let task = Process()

    private let stdin = Pipe()
    private let stdout = Pipe()
    private let stderr = Pipe()

    fileprivate var progressBuf = ""
    fileprivate var outputBuf = ""

    var onLogProgress: ((String) -> ())?
    var onLogOutput: ((String) -> ())?
    var onComplete: (() -> ())?

    init(_ launchPath: String, arguments: [String], environment: [String: String]? = nil) {
//        task.standardInput = stdin
        task.standardOutput = stdout
        task.standardError = stderr

        task.launchPath = launchPath
        task.arguments = arguments
        task.environment = environment

        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let `self` = self else { return }

            self.progressBuf += String(data: handle.availableData, encoding: .utf8)!
        }

        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let `self` = self else { return }

            self.outputBuf += String(data: handle.availableData, encoding: .utf8)!

            var lines = self.outputBuf.components(separatedBy: "\n")

            if let output = self.onLogOutput, lines.count > 1 {
                self.outputBuf = lines.popLast()!

                lines.forEach(output)
            }
        }

        task.terminationHandler = { [weak self] _ in
            guard let `self` = self else { return }

            if self.exitCode == 0 {
                self.onComplete?()
            }

            // Avoids memory leaks.
            self.onLogOutput = nil
            self.onLogProgress = nil
            self.onComplete = nil
        }
    }

    var currentDirectoryPath: String {
        get { return task.currentDirectoryPath }
        set { task.currentDirectoryPath = newValue }
    }

    var exitCode: Int32 {
        return task.terminationStatus
    }

    var isRunning: Bool {
        return task.isRunning
    }

    var output: String {
        return progressBuf
    }

    func launch() {
        task.launch()
    }

    func terminate() {
        task.terminate()
    }

    func waitUntilExit() {
        task.waitUntilExit()
    }

    func write(string: String, withNewline: Bool = true) {
        let handle = stdin.fileHandleForWriting
        handle.write(string.data(using: .utf8)!)

        if withNewline {
            handle.write("\n".data(using: .utf8)!)
        }
    }
}
