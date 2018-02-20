//
//  ISO639.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-18.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

struct ISO639Data {
    let tag3: String
    let tag1: String
    let name: String
    let autonym: String?
    let source: String
    
    fileprivate init(row: [String]) {
        tag1 = row[0]
        tag3 = row[1]
        name = row[2]
        autonym = row[3] == "" ? nil : row[3]
        source = row[4]
    }
}

class ISO639 {
    private static let data: [ISO639Data] = {
        let tsvPath = Bundle.main.url(forResource: "iso639-autonyms", withExtension: "tsv")!
        let document = try! String(contentsOf: tsvPath, encoding: .utf8)
        return document.components(separatedBy: .newlines)
            .map { ISO639Data(row: $0.components(separatedBy: "\t")) }
    }()
    
    static func get(tag: String) -> ISO639Data? {
        return data.first(where: { $0.tag1 == tag || $0.tag3 == tag })
    }
    
    private init() {}
}
