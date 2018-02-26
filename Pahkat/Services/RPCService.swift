//
//  RPCService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-16.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct RepositoryRequest {
    let url: URL
}

extension RepositoryRequest: JSONRPCRequest {
    typealias Response = RepositoryIndex
    
    var method: String { return "repository" }
    var params: Any? { return [url.absoluteString] }
}

struct PackageInstallStatusRequest {
    let package: Package
    let target: MacOsInstaller.Targets
}

extension PackageInstallStatusRequest: JSONRPCRequest {
//    typealias Response = [String: PackageInstallStatus]
    typealias Response = PackageInstallStatus
    
    var method: String { return "status" }
    var params: Any? { return [package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
}

struct InstallRequest {
    let package: Package
    let target: MacOsInstaller.Targets
}

extension InstallRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "install" }
    var params: Any? { return [package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
}

struct UninstallRequest {
    let package: Package
    let target: MacOsInstaller.Targets
}

extension UninstallRequest: JSONRPCRequest {
    typealias Response = PackageInstallStatus
    
    var method: String { return "uninstall" }
    var params: Any? { return [package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
}

struct DownloadSubscriptionRequest {
    let package: Package
    let target: MacOsInstaller.Targets
}

extension DownloadSubscriptionRequest: JSONRPCSubscriptionRequest {
    typealias Response = [UInt64]
    
    var method: String { return "download_subscribe" }
    var unsubscribeMethod: String? { return "download_unsubscribe" }
    var params: Any? { return [package.id, target == MacOsInstaller.Targets.system ? 0 : 1] }
    var callback: String { return "download" }
}

struct SettingsRequest: JSONRPCRequest {
    typealias Response = SettingsState
    
    var method: String { return "settings" }
    var params: Any? { return [] }
}

struct SetSettingsRequest: JSONRPCRequest {
    let settings: SettingsState
    
    typealias Response = Bool
    
    var method: String { return "set_settings" }
    var params: Any? { return [settings] }
}

protocol PahkatRPCServiceable: class {
//    func get(repository url: URL) throws -> Single<RepositoryRequest.Response>
//    func status(of packages: [Package], forRepository url: URL) throws -> Single<PackageInstallStatusesRequest.Response>
//    func download(package: Package, forRepository url: URL) throws -> Observable<DownloadSubscriptionRequest.Response>
//    func install(package: Package, forRepository url: URL) throws -> Observable<InstallSubscriptionRequest.Response>
//    func uninstall(package: Package, forRepository url: URL) throws -> Observable<InstallSubscriptionRequest.Response>
}

class PahkatRPCService: PahkatRPCServiceable {
    private let bag = DisposeBag()
    
    private let process: BufferedStringSubprocess
    internal let pahkatcIPC: BufferedStringSubprocess
    private let rpc = JSONRPCClient()
    
    static let pahkatcPath = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/pahkatc")
    
    public init(requiresAdmin: Bool = false) {
        pahkatcIPC = BufferedStringSubprocess(
            PahkatRPCService.pahkatcPath.path,
            arguments: ["ipc"],
            qos: QualityOfService.userInteractive)
        
        pahkatcIPC.standardOutput = {
            print($0)
        }

        pahkatcIPC.standardError = {
            print($0)
        }

        pahkatcIPC.onComplete = {
            print("IPC is dead.")
        }
//
        pahkatcIPC.launch()
        if !pahkatcIPC.isRunning {
            usleep(100000)
        }
        sleep(1)
        
        // TODO: monitor on Rust-side for when connections hits zero after incrementing to above zero to dezombie
        
        process = BufferedStringSubprocess("/usr/bin/nc", arguments: ["localhost", "3030"], qos: QualityOfService.userInteractive)

        // Handle input from process
        process.standardOutput = { [unowned self] in
//            print($0)
            guard let data = $0.data(using: .utf8) else { return }
            self.rpc.input.onNext(data)
        }

        // Handle output to process
        rpc.output.subscribe(onNext: { [weak self] in
            let string = String(data: $0, encoding: .utf8)!
//            print(string)
            self?.process.write(string: string)
        }).disposed(by: bag)

        process.launch()
        
        print("IPC server running: \(pahkatcIPC.isRunning)")
        print("RPC client running: \(process.isRunning)")
    }
    
    deinit {
        print("PahkatRPCService DEINIT")
        process.terminate()
        pahkatcIPC.terminate()
    }
    
    func repository(with url: URL) throws -> Single<RepositoryRequest.Response> {
        return try rpc.send(request: RepositoryRequest(url: url))
    }
    
    func status(of package: Package, target: MacOsInstaller.Targets) throws -> Single<PackageInstallStatusRequest.Response> {
        return try rpc.send(request: PackageInstallStatusRequest(package: package, target: target))
    }
    
    func download(_ package: Package, target: MacOsInstaller.Targets) throws -> Observable<PackageDownloadStatus> {
        return try rpc.send(subscription: DownloadSubscriptionRequest(package: package, target: target))
            .flatMapLatest { (raw: [UInt64]) -> Observable<PackageDownloadStatus> in
                let cur = raw[0]
                let max = raw[1]
                
                if cur == 0 { return Observable.just(.starting) }
                if cur == max { return Observable.of(.progress(downloaded: cur, total: max), .completed) }
                return Observable.just(.progress(downloaded: cur, total: max))
            }
            .startWith(.notStarted)
    }

    func install(_ package: Package, target: MacOsInstaller.Targets) throws -> Single<InstallRequest.Response> {
        return try rpc.send(request: InstallRequest(package: package, target: target))
    }

    func uninstall(_ package: Package, target: MacOsInstaller.Targets) throws -> Single<UninstallRequest.Response> {
        return try rpc.send(request: UninstallRequest(package: package, target: target))
    }
    
    func settings() throws -> Single<SettingsRequest.Response> {
        return try rpc.send(request: SettingsRequest())
    }
    
    func set(settings: SettingsState) throws -> Single<SetSettingsRequest.Response> {
        return try rpc.send(request: SetSettingsRequest(settings: settings))
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
//    var params: Any? { return [10] }
//    var callback: String { return "hello" }
//    var unsubscribeMethod: String? { return "hello_unsubscribe" }
//}

