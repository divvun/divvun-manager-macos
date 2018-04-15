//
//  BufferedProcess.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

enum TaskLaunchResult {
    case launched
    case cancelled
    case failure(NSError)
}

protocol BufferedProcess: class {
    var onComplete: ((Int32) -> ())? { set get }
    var standardOutput: ((String) -> ())? { set get }
    var standardError: ((String) -> ())? { set get }
    func write(string: String, withNewline: Bool)
    func launch() -> TaskLaunchResult
    var isRunning: Bool { get }
    func terminate()
    func waitUntilExit()
}

class BufferedStringSubprocess: BufferedProcess {
    private let task = Process()
    
    private let stdin = Pipe()
    private let stdout = Pipe()
    private let stderr = Pipe()
    
    private func handler(_ output: ((String) -> ())?, for pipe: Pipe) {
        guard let output = output else {
            pipe.fileHandleForReading.readabilityHandler = nil
            return
        }
        
        var outputBuf = ""
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
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
    
    var standardOutput: ((String) -> ())? {
        didSet {
            handler(standardOutput, for: stdout)
        }
    }
    
    var standardError: ((String) -> ())? {
        didSet {
            handler(standardError, for: stderr)
        }
    }
    
    var onComplete: ((Int32) -> ())?
    
    init(_ launchPath: String, arguments: [String], environment: [String: String]? = nil, qos: QualityOfService? = nil) {
        task.standardInput = stdin
        task.standardOutput = stdout
        task.standardError = stderr
        
        task.launchPath = launchPath
        task.arguments = arguments
        
        if let environment = environment {
            task.environment = environment
        }
        
        if let qos = qos {
            task.qualityOfService = qos
        }
        
        task.terminationHandler = { [weak self] _ in
            guard let `self` = self else { return }
            
            print("Exit code (\(self.task.launchPath!)): \(self.exitCode)")
            
            self.onComplete?(self.exitCode)
            
            // Avoids memory leaks.
            self.standardOutput = nil
            self.standardError = nil
            self.onComplete = nil
        }
    }
    
    func write(string: String, withNewline: Bool = true) {
        let handle = stdin.fileHandleForWriting
        
        handle.write(string.data(using: .utf8)!)
        
        if withNewline {
            handle.write("\n".data(using: .utf8)!)
        }
    }
    
    deinit {
        task.terminate()
        
        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        
        self.standardOutput = nil
        self.standardError = nil
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
        task.launch()
        return .launched
    }
    
    func terminate() {
        task.terminate()
    }
    
    func waitUntilExit() {
        task.waitUntilExit()
    }
}
