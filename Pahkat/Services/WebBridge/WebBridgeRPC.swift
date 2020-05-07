import Foundation


struct WebBridgeRequest: Codable {
    let id: UInt
    let method: String
    let args: [JSONValue]
}

struct ErrorResponse: Error, Codable {
    let error: String
}
