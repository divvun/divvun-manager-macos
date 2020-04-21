import Foundation

extension LoadedRepository {
    static func mock(id: String) -> LoadedRepository {
        let index = LoadedRepository.Index(url: URL(string: id)!,
                                           landingURL: nil,
                                           channels: ["wildly-unstable"],
                                           defaultChannel: nil,
                                           name: ["uhh": "not sure"],
                                           description: ["greetings": "have a milkshake"],
                                           linkedRepositories: [],
                                           acceptedRedirections: [],
                                           agent: Index.Agent(name: "mOcK", version: "0.0", url: nil))
        let meta = LoadedRepository.Meta(channel: "MTV")
        return LoadedRepository(index: index, meta: meta, packages: PackagesMock())
    }

    class PackagesMock: PackagesProto {
        var packages: RefMap<String, Package> {
            return RefMap(ptr: UnsafeMutableRawPointer(bitPattern: 1)!,
                          count: 0,
                          keyGetter: { (_) -> String in
                            "key"
            }, valueGetter: { (_) -> Package? in
                nil
            })
        }
    }
}
