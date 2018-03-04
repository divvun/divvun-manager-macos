//
//  MainOutlineModels.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-02.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift

protocol NSOutlineViewMenu: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, menuFor item: Any) -> NSMenu?
}

class PackageOutlineView: NSOutlineView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = self.convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        guard let item = self.item(atRow: row) else {
            return nil
        }
        
        return (self.delegate as? NSOutlineViewMenu)?.outlineView(self, menuFor: item)
    }
}

enum MainViewOutlineColumns: String {
    case name = "name"
    case version = "version"
    case state = "state"
    
    init?(identifier: NSUserInterfaceItemIdentifier) {
        if let value = MainViewOutlineColumns(rawValue: identifier.rawValue) {
            self = value
        } else {
            return nil
        }
    }
}

class OutlineGroup: Equatable, Comparable {
    let id: String
    let value: String
    
    init(id: String, value: String) {
        self.id = id
        self.value = value
    }
    
    static func ==(lhs: OutlineGroup, rhs: OutlineGroup) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value
    }
    
    static func <(lhs: OutlineGroup, rhs: OutlineGroup) -> Bool {
        switch lhs.value.localizedCaseInsensitiveCompare(rhs.value) {
        case .orderedAscending:
            return true
        default:
            return false
        }
    }
}

class OutlinePackage: Equatable {
    let package: Package
    var action: PackageAction?
    
    init(package: Package, action: PackageAction?) {
        self.package = package
        self.action = action
    }
    
    static func ==(lhs: OutlinePackage, rhs: OutlinePackage) -> Bool {
        return lhs.package == rhs.package && lhs.action == rhs.action
    }
}

enum OutlineItem: Equatable {
    case repository(OutlineRepository)
    case group(OutlineGroup, OutlineRepository)
    case item(OutlinePackage, OutlineGroup, OutlineRepository)
    
    static func ==(lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        switch (lhs, rhs) {
        case let (.repository(a), .repository(b)):
            return a == b
        case let (.group(a, ar), .group(b, br)):
            return a == b && ar == br
        case let (.item(a, ag, ar), .item(b, bg, br)):
            return a == b && ag == bg && ar == br
        default:
            return false
        }
    }
}

enum OutlineEvent {
    case setPackageAction(PackageAction)
    case togglePackage(OutlineRepository, Package)
    case toggleGroup(OutlineRepository, OutlineGroup)
    case changeFilter(OutlineRepository, Repository.PrimaryFilter)
}

class OutlineCheckbox: NSButton {
    var event: OutlineEvent?
}

class OutlineRepository: Equatable, Comparable {
    let repo: RepositoryIndex
    var filter: Repository.PrimaryFilter
    
    init(filter: Repository.PrimaryFilter, repo: RepositoryIndex) {
        self.filter = filter
        self.repo = repo
    }
    
    static func ==(lhs: OutlineRepository, rhs: OutlineRepository) -> Bool {
        return lhs.repo == rhs.repo
    }
    
    static func <(lhs: OutlineRepository, rhs: OutlineRepository) -> Bool {
        return lhs.repo < rhs.repo
    }
}
