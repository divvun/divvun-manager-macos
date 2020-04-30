import Foundation
import FlatBuffers

extension LoadedRepository {
    static func mock(id: String) -> LoadedRepository {
        let index = LoadedRepository.Index(url: URL(string: "https://isitchristmas.com/\(id)")!,
                                           landingURL: nil,
                                           channels: ["wildly-unstable"],
                                           defaultChannel: nil,
                                           name: ["en": "Mock\(id)"],
                                           description: ["greetings": "have a milkshake"],
                                           linkedRepositories: [],
                                           acceptedRedirections: [],
                                           agent: Index.Agent(name: "mOcK", version: "0.0", url: nil))
        let meta = LoadedRepository.Meta(channel: "MTV")

        let data = try! Data(contentsOf: URL(fileURLWithPath: "/Users/brendan/git/divvun-pahkat-repo/packages/index.bin"))
        let packagesFbs = pahkat.Packages.getRootAsPackages(bb: ByteBuffer(data: data))
        let rawPackages = Packages(packagesFbs)

        return LoadedRepository(index: index, meta: meta, packages: rawPackages)
    }

//    class PackagesMock: PackagesProto {
//        let descriptors: [Descriptor] = [
//            Descriptor(
//        ]
//
//        var packages: RefMap<String, Package> {
//            return RefMap(ptr: UnsafeMutableRawPointer.allocate(byteCount: 0, alignment: 0),
//                          count: 0,
//                          keyGetter: { (i) -> String in
//                            "key"
//            }, valueGetter: { (_) -> Package? in
//                nil
//            })
//        }
//        var descriptors: RefMap<String, Descriptor> {
//            return RefMap(ptr: UnsafeMutableRawPointer.allocate(byteCount: 0, alignment: 0),
//                          count: 0,
//                          keyGetter: { (i) -> String in
//                            "key"
//            }, valueGetter: { (i) -> Descriptor? in
//                nil
//            })
//        }
//    }
}
