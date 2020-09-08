import Foundation

struct DownloadError: Error, Codable {
    let message: String
}

enum PackageDownloadStatus {
    case notStarted
    case starting
    case progress(downloaded: UInt64, total: UInt64)
    case completed
    case error(DownloadError)
}
