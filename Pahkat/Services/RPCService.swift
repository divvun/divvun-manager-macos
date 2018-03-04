//
//  RPCService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-16.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct RepositoryRequest: Codable {
    let config: RepoConfig
}

extension RepositoryRequest: JSONRPCRequest {
    typealias Response = RepositoryIndex
    
    var method: String { return "repository" }
    var params: Encodable? { return [config.url.absoluteString, config.channel.rawValue] }
}

struct RepositoryStatusesRequest {
    let url: URL
}

struct PackageStatusResponse: Codable {
    let status: PackageInstallStatus
    let target: MacOsInstaller.Targets
}

extension RepositoryStatusesRequest: JSONRPCRequest {
    typealias Response = [String: PackageStatusResponse]
    
    var method: String { return "repository_statuses" }
    var params: Encodable? { return [url.absoluteString] }
}

struct PackageInstallStatusRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension PackageInstallStatusRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "status" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
}

struct InstallRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension InstallRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "install" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
}

struct UninstallRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension UninstallRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "uninstall" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
}

struct DownloadSubscriptionRequest {
    let repo: RepositoryIndex
    let package: Package
    let target: MacOsInstaller.Targets
}

extension DownloadSubscriptionRequest: JSONRPCSubscriptionRequest {
    typealias Response = [UInt64]
    
    var method: String { return "download_subscribe" }
    var unsubscribeMethod: String? { return "download_unsubscribe" }
    var params: Encodable? { return [repo.meta.base.absoluteString, package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
    var callback: String { return "download" }
}

struct SettingsRequest: JSONRPCRequest {
    typealias Response = SettingsState
    
    var method: String { return "settings" }
    var params: Encodable? { return [] }
}

struct SetSettingsRequest: JSONRPCRequest {
    let settings: SettingsState
    
    typealias Response = Bool
    
    var method: String { return "set_settings" }
    var params: Encodable? { return [settings] }
}

class PahkatRPCService {
    private let bag = DisposeBag()
    
    internal let pahkatcIPC: BufferedProcess
    private let rpc = JSONRPCClient()
    
    static let pahkatcPath = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/pahkatc")
    
    public convenience init?() {
//        if requiresAdmin {
//            pahkatcIPC = AdminSubprocess(PahkatRPCService.pahkatcPath.path, arguments: ["ipc"])
//        } else {
        self.init(service: BufferedStringSubprocess(
            PahkatRPCService.pahkatcPath.path,
            arguments: ["ipc"],
            qos: QualityOfService.userInteractive))
//        }
        
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
        
        pahkatcIPC.standardError = {
            print($0)
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
//        process.terminate()
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

//
//class MockRPCService: RPCService {
//    func hello() throws -> Observable<String> {
//        return try rpc.send(subscription: Hello())
//    }
//}
//
//struct SayHello: JSONRPCRequest {
//    typealias Response = String
//    var method: String { return "say_hello" }
//}
//
//struct Hello: JSONRPCSubscriptionRequest {
//    typealias Response = String
//
//    var method: String { return "hello_subscribe" }
//    var params: Encodable? { return [10] }
//    var callback: String { return "hello" }
//    var unsubscribeMethod: String? { return "hello_unsubscribe" }
//}

