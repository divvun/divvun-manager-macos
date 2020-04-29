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
