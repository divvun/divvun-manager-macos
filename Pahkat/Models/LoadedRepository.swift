//
//  LoadedRepository.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2020-04-16.
//  Copyright © 2020 Divvun. All rights reserved.
//

import Foundation
import FlatBuffers

enum LoadedRepositoryError: Error {
    case invalidURL(String)
    case invalidLinkedRepositoryURL(String)
    case invalidAcceptedRedirectionURL(String)
    case missingDescriptorID(pahkat.Descriptor)
    case missingVersion(pahkat.Release, Descriptor)
    case missingAgentName
    case missingAgentVersion
}

struct LoadedRepository: Hashable, Equatable {
    static func == (lhs: LoadedRepository, rhs: LoadedRepository) -> Bool {
        lhs.index.url.absoluteString == rhs.index.url.absoluteString
    }

    static func <(lhs: LoadedRepository, rhs: LoadedRepository) -> Bool {
        return lhs.index.url.absoluteString < rhs.index.url.absoluteString
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.index.url)
    }
    
    struct Index: Hashable, Equatable {
        struct Agent: Hashable, Equatable {
            let name: String
            let version: String
            let url: URL?
        }
        
        let url: URL
        let landingURL: URL?
        let channels: Set<String>
        let defaultChannel: String?
        let name: [String: String]
        let description: [String: String]
        let linkedRepositories: [URL]
        let acceptedRedirections: [URL]
        let agent: Agent
    }
    
    struct Meta: Hashable, Equatable {
        let channel: String?
    }
    
    private let rawPackages: Packageable
    
    let index: Index
    let meta: Meta
    var packages: RefMap<String, Package> { rawPackages.packages }
    var descriptors: RefMap<String, Descriptor> { rawPackages.descriptors }
    
    static func from(protobuf: Pahkat_LoadedRepository) throws -> LoadedRepository {
        let packagesFbs = pahkat.Packages.getRootAsPackages(bb: ByteBuffer(data: protobuf.packagesFbs))
        let rawPackages = Packages(packagesFbs)
        
        let meta = Meta(
            channel: protobuf.meta.channel == "" ? nil : protobuf.meta.channel
        )
        
        let i = protobuf.index
        
        guard let url = URL(string: i.url) else {
            throw LoadedRepositoryError.invalidURL(i.url)
        }
        
        let landingURL = URL(string: i.landingURL)
        let channels = Set(i.channels)
        let defaultChannel = i.defaultChannel == "" ? nil : i.defaultChannel
        let linkedRepositories: [URL] = try i.linkedRepositories.map {
            guard let url = URL(string: $0) else {
                throw LoadedRepositoryError.invalidLinkedRepositoryURL($0)
            }
            return url
        }
        let acceptedRedirections: [URL] = try i.acceptedRedirections.map {
            guard let url = URL(string: $0) else {
                throw LoadedRepositoryError.invalidAcceptedRedirectionURL($0)
            }
            return url
        }
        
        guard let agentName = i.agent.name == "" ? nil : i.agent.name else {
            throw LoadedRepositoryError.missingAgentName
        }
        
        guard let agentVersion = i.agent.version == "" ? nil : i.agent.version else {
            throw LoadedRepositoryError.missingAgentVersion
        }
        
        let agent = Index.Agent(name: agentName, version: agentVersion, url: URL(string: i.agent.url))
        
        let index = Index(
            url: url,
            landingURL: landingURL,
            channels: channels,
            defaultChannel: defaultChannel,
            name: i.name,
            description: i.description_p,
            linkedRepositories: linkedRepositories,
            acceptedRedirections: acceptedRedirections,
            agent: agent)
        
        return LoadedRepository(
            index: index,
            meta: meta,
            packages: rawPackages)
    }
    
    public init<T: Packageable>(index: Index, meta: Meta, packages: T) {
        self.index = index
        self.meta = meta
        self.rawPackages = packages
    }
}

extension LoadedRepository.Index {
    var nativeName: String {
        return self.name["en"] ?? "<unknown repo name>"
    }
    
    var nativeDescription: String {
        return self.name["en"] ?? "<unknown repo desc>"
    }
}

extension LoadedRepository {
    func packageKey(for descriptor: Descriptor) -> PackageKey {
        return PackageKey(repositoryURL: self.index.url, id: descriptor.id)
    }
}
