//
//  WebBridgeRPC.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-05-06.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation


struct WebBridgeRequest: Codable {
    let id: UInt
    let method: String
    let args: [JSONValue]
}

struct ErrorResponse: Error, Codable {
    let error: String
}
