//
//  AdminSubprocess.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import STPrivilegedTask

extension STPrivilegedTask {
    func launchSafe() -> TaskLaunchResult {
        let status = self.launch()
        switch status {
        case 0:
            return .launched
        case -60006:
            return .cancelled
        default:
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            return .failure(error)
        }
    }
}

class AdminSubprocess: BufferedProcess {
    private let task: STPrivilegedTask
    
    var onComplete: ((Int32) -> ())?
    
    init(_ launchPath: String, arguments: [String]) {
        task = STPrivilegedTask(launchPath: launchPath, arguments: arguments)
        
        task.terminationHandler = { [weak self] _ in
            guard let `self` = self else { return }
            
            print("Exit code (\(self.task.launchPath!)): \(self.exitCode)")
            
            self.onComplete?(self.exitCode)
            
            // Avoids memory leaks.
            self.standardOutput = nil
            self.onComplete = nil
        }
    }
    
    var standardOutput: ((String) -> ())?
    
    // Stub for protocol.
    var standardError: ((String) -> ())?
    
    func write(string: String, withNewline: Bool = true) {
        guard let handle = task.outputFileHandle else { return }
        
        handle.write(string.data(using: .utf8)!)
        
        if withNewline {
            handle.write("\n".data(using: .utf8)!)
        }
    }
    
    deinit {
        task.terminate()
        
        task.outputFileHandle?.readabilityHandler = nil
        
        self.standardOutput = nil
        self.onComplete = nil
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
    
    func launch() -> TaskLaunchResult {
        let result = task.launchSafe()
        
        switch result {
        case .launched:
            handler(standardOutput, for: task.outputFileHandle)
        default:
            break
        }
        
        return result
    }
    
    func terminate() {
        task.terminate()
    }
    
    func waitUntilExit() {
        task.waitUntilExit()
    }
    
    private func handler(_ output: ((String) -> ())?, for fileHandle: FileHandle) {
        guard let output = output else {
            fileHandle.readabilityHandler = nil
            return
        }
        
        var outputBuf = ""
        
        fileHandle.readabilityHandler = { handle in
            guard let string = String(data: handle.availableData, encoding: .utf8) else {
                return
            }
            
            outputBuf += string
            
            if !outputBuf.contains("\n") {
                return
            }
            
            var lines = outputBuf.components(separatedBy: "\n")
            
            if lines.count > 1 {
                outputBuf = lines.popLast()!
                lines.forEach(output)
            }
        }
    }
}
