//
//  SettingsViewController.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class SettingsViewController: DisposableViewController<SettingsView>, SettingsViewable {
    
    private var tableDelegate: RepositoryTableDelegate! = nil

    override func viewWillAppear() {
        super.viewWillAppear()
        
        contentView.frequencyLabel.stringValue = Strings.updateFrequency
        contentView.channelLabel.stringValue = Strings.updateChannel
        //TODO: add repositories localise
        contentView.repoLabel.stringValue = Strings.repository
        
        UpdateFrequency.asMenuItems().forEach({ contentView.frequencyPopUp.menu?.addItem($0) })
        UpdateChannels.asMenuItems().forEach({ contentView.channelPopUp.menu?.addItem($0) })
    }
    
    func setRepositories(repositories: [Repository]) {
        self.tableDelegate = RepositoryTableDelegate(with: repositories)
        contentView.repoTableView.delegate = self.tableDelegate
        contentView.repoTableView.dataSource = self.tableDelegate
    }
    
}

enum RepositoryTableColumns: String {
    case name
    case url
    
    init?(identifier: NSUserInterfaceItemIdentifier) {
        if let value = RepositoryTableColumns(rawValue: identifier.rawValue){
            self = value
        } else {
            return nil
        }
    }
}

class RepositoryTableDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    private var repos: [Repository]
    
    init(with repositories: [Repository]) {
        self.repos = repositories
        super.init()
    }
    
    func add(repository:Repository) {
        repos.append(repository)
    }
    
    func remove(repository: Repository) {
        guard let index = repos.index(of: repository) else { return }
        
        repos.remove(at: index)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        guard let column = RepositoryTableColumns(identifier: tableColumn.identifier) else { return nil }
        
        let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        let repo = repos[row]
        
        switch column {
        case .name:
            cell.textField?.stringValue = repo.name[Strings.languageCode ?? "en"] ?? ""
        case .url:
            cell.textField?.stringValue = repo.base.absoluteString
        }
        
        return cell
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.repos.count
    }
    
}


extension NSMenuItem {
    convenience init(title: String, value: Any) {
        self.init(title: title, target: nil, action: nil)
        self.representedObject = value
    }
}

extension UpdateFrequency {
    private static func createMenuItem(_ thingo: UpdateFrequency) -> NSMenuItem {
        return NSMenuItem(title: thingo.description, value: thingo.rawValue)
    }
    
    static func asMenuItems() -> [NSMenuItem] {
        return [
            UpdateFrequency.createMenuItem(.daily),
            UpdateFrequency.createMenuItem(.weekly),
            UpdateFrequency.createMenuItem(.fortnightly),
            UpdateFrequency.createMenuItem(.monthly),
            UpdateFrequency.createMenuItem(.never)
        ]
    }
}

extension UpdateChannels {
    private static func createMenuItem(_ thingo: UpdateChannels) -> NSMenuItem {
        return NSMenuItem(title: thingo.description, value: thingo.rawValue)
    }
    
    static func asMenuItems() -> [NSMenuItem] {
        return [
            UpdateChannels.createMenuItem(.stable),
            UpdateChannels.createMenuItem(.alpha),
            UpdateChannels.createMenuItem(.beta),
            UpdateChannels.createMenuItem(.nightly),
        ]
    }
}


