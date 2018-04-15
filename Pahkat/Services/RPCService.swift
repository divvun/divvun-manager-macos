//
//  RPCService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-16.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class PahkatRPCService {
    private let bag = DisposeBag()
    
    internal let pahkatcIPC: BufferedProcess
    private let rpc = JSONRPCClient()
    
    static let pahkatcPath = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/pahkatc")
    
    public convenience init?() {
        self.init(service: BufferedStringSubprocess(
            PahkatRPCService.pahkatcPath.path,
            arguments: ["ipc"],
            qos: QualityOfService.userInteractive))
    }
    
    internal init?(service: BufferedProcess) {
        pahkatcIPC = service
        
        if !setUp() {
            return nil
        }
    }
    
    private func setUp() -> Bool {
        // Handle input from process
        pahkatcIPC.standardOutput = { [unowned self] in
            guard let data = $0.data(using: .utf8) else {
                print($0)
                return
            }
            self.rpc.input.onNext(data)
        }
        
        pahkatcIPC.standardError = { line in
            print(line)
        }
        
        // Handle output to process
        rpc.output.subscribe(onNext: { [weak self] in
            let string = String(data: $0, encoding: .utf8)!
            self?.pahkatcIPC.write(string: string, withNewline: true)
        }).disposed(by: bag)
        
        switch pahkatcIPC.launch() {
        case .launched:
            break
        default:
            return false
        }
        
        if !pahkatcIPC.isRunning {
            usleep(100000)
        }
        
        print("IPC server running: \(pahkatcIPC.isRunning)")
        return true
    }
    
    deinit {
        print("PahkatRPCService DEINIT")
        pahkatcIPC.terminate()
    }
    
    func repository(with config: RepoConfig) throws -> Single<RepositoryRequest.Response> {
        return try rpc.send(request: RepositoryRequest(config: config))
    }
    
    func statuses(for url: URL) throws -> Single<RepositoryStatusesRequest.Response> {
        return try rpc.send(request: RepositoryStatusesRequest(url: url))
    }
    
    func download(_ package: Package, repo: RepositoryIndex, target: MacOsInstaller.Targets) throws -> Observable<PackageDownloadStatus> {
        return try rpc.send(subscription: DownloadSubscriptionRequest(repo: repo, package: package, target: target))
            .flatMapLatest { (raw: [UInt64]) -> Observable<PackageDownloadStatus> in
                let cur = raw[0]
                let max = raw[1]
                
                if cur == 0 { return Observable.just(.starting) }
                if cur == max { return Observable.of(.progress(downloaded: cur, total: max), .completed) }
                return Observable.just(.progress(downloaded: cur, total: max))
            }
            .startWith(.notStarted)
    }

    func install(_ package: Package, repo: RepositoryIndex, target: MacOsInstaller.Targets) throws -> Single<InstallRequest.Response> {
        return try rpc.send(request: InstallRequest(repo: repo, package: package, target: target))
    }

    func uninstall(_ package: Package, repo: RepositoryIndex, target: MacOsInstaller.Targets) throws -> Single<UninstallRequest.Response> {
        return try rpc.send(request: UninstallRequest(repo: repo, package: package, target: target))
    }
}

