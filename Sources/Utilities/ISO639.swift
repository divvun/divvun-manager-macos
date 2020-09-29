import Foundation

// Language tags
struct ISO639Data {
    let tag3: String // 3 chars eg "smj"
    let tag1: String // 2 chars eg "se"
    let name: String
    let autonym: String?
    let source: String
    
    var autonymOrName: String {
        return autonym ?? name
    }
    
    fileprivate init(row: [String]) {
        tag3 = row[0]
        tag1 = row[1]
        name = row[2]
        autonym = row[3] == "" ? nil : row[3]
        source = row[4]
    }
}

class ISO639 {
    private static let data: [ISO639Data] = {
        let tsvPath = Bundle.main.url(forResource: "iso639-autonyms", withExtension: "tsv")!
        let document = try! String(contentsOf: tsvPath, encoding: .utf8)
        return document.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .suffix(from: 1)
            .map { ISO639Data(row: $0.components(separatedBy: "\t")) }
    }()
    
    static func get(tag: String) -> ISO639Data? {
        return data.first(where: { $0.tag1 == tag || $0.tag3 == tag })
    }
    
    private init() {}
}
