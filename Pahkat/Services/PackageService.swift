//
//  PackageService.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

enum PackageInstallStatus: String, Codable {
    case notInstalled
    case upToDate
    case requiresUpdate
    case versionSkipped
}

struct DownloadError: Error, Codable {
    let message: String
}

enum PackageDownloadStatus: Decodable {
    case notStarted
    case starting
    case progress(downloaded: UInt64, total: UInt64)
    case completed
    case error(DownloadError)
    
    private enum CodingKeys: String, CodingKey {
        case discriminator = "k"
        case value = "v"
    }
    
    private enum Keys: String, Codable {
        case notStarted = "not_started"
        case starting
        case progress
        case completed
        case error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let discriminator = try container.decode(Keys.self, forKey: .discriminator)
        switch discriminator {
        case .notStarted:
            self = .notStarted
        case .starting:
            self = .starting
        case .progress:
            let values = try container.decode([UInt64].self, forKey: .value)
            self = .progress(downloaded: values[0], total: values[1])
        case .completed:
            self = .completed
        case .error:
            let error = try container.decode(DownloadError.self, forKey: .value)
            self = .error(error)
        }
    }
}

enum PackageInstallProgress {
    case start
    case finish
    case error(Error)
}

class PackageService {
    func status(package: Package) -> Single<PackageInstallStatus> {
        // TODO: subprocess
        return Single.just(.notInstalled)
    }
    
    func download(packages: [Package]) -> Observable<PackageDownloadStatus> {
        // TODO: subprocess
        return Observable<PackageDownloadStatus>.of(
            .notStarted,
            .starting,
            .progress(downloaded: 0, total: 100),
            .progress(downloaded: 50, total: 100),
            .progress(downloaded: 100, total: 100),
            .completed)
    }
    
    func uninstall(packages: [Package]) -> Observable<PackageInstallProgress> {
        // This can be cancelled by disposing the disposable when subscribed.
//        return Observable<PackageInstallProgress>.create { observer in
//            let packageDisposable = Observable.from(packages)
//                .flatMapLatest { (package: Package) -> Observable< in
//                    observer.onNext(.start(package))
//                }
//        }
        fatalError()
    }
    
    func install(packages: [Package]) -> Observable<PackageInstallProgress> {
        fatalError()
    }
}
