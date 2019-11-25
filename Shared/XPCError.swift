//
//  XPCError.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-11-18.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Foundation

struct XPCError: Error, Codable {
    static func from(error: Error) -> XPCError {
        return XPCError(message: error.localizedDescription)
    }
 
    let message: String
}
