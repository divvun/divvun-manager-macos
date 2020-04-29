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

private let ISO639_3_NO_LANGUAGE = "zxx"

class OutlineGroup: Equatable, Comparable {
    let id: String
    let value: String
    let repo: OutlineRepository
    
    init(id: String, value: String, repo: OutlineRepository) {
        self.id = id
        self.value = value
        self.repo = repo
    }
    
    static func ==(lhs: OutlineGroup, rhs: OutlineGroup) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value
    }
    
    static func <(lhs: OutlineGroup, rhs: OutlineGroup) -> Bool {
        // Handle "zxx" case, and move to bottom always
        if lhs.id == ISO639_3_NO_LANGUAGE { return false }
        if rhs.id == ISO639_3_NO_LANGUAGE { return true }
        
        switch lhs.value.localizedCaseInsensitiveCompare(rhs.value) {
        case .orderedAscending:
            return true
        default:
            return false
        }
    }
}

class OutlinePackage: Equatable, Comparable {
    let package: Descriptor
    let release: Release
    let target: Target
    let status: (PackageStatus, SystemTarget)
    
    let group: OutlineGroup
    let repo: OutlineRepository
    var selection: SelectedPackage?
    
    init(package: Descriptor, release: Release, target: Target, status: (PackageStatus, SystemTarget), group: OutlineGroup, repo: OutlineRepository, selection: SelectedPackage?) {
        self.package = package
        self.release = release
        self.target = target
        self.status = status
        self.group = group
        self.repo = repo
        self.selection = selection
    }
    
    static func ==(lhs: OutlinePackage, rhs: OutlinePackage) -> Bool {
        return lhs.package == rhs.package && lhs.selection == rhs.selection
    }
    
    static func <(lhs: OutlinePackage, rhs: OutlinePackage) -> Bool {
        if lhs.package.nativeName == rhs.package.nativeName {
            return lhs.package.hashValue < rhs.package.hashValue
        }
        
        return lhs.package.nativeName < rhs.package.nativeName
    }
}

enum OutlineFilter {
    case category
    case language
}

enum OutlineEvent {
    case setPackageSelection(SelectedPackage)
    case togglePackage(OutlinePackage)
    case toggleGroup(OutlineGroup)
    case changeFilter(OutlineRepository, OutlineFilter)
}

class OutlineCheckbox: NSButton {
    var event: OutlineEvent?
}

class OutlineRepository: Equatable, Comparable {
    let repo: LoadedRepository
    var filter: OutlineFilter
    
    init(filter: OutlineFilter, repo: LoadedRepository) {
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
