//
//  UpdateViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-15.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class UpdateViewController: DisposableViewController<UpdateView>, UpdateViewable {
    
    func updateSelectedPackages(packages: [Package]) {
        self.tableDelegate.selectedPackages = packages
        self.contentView.tableView.reloadData()
        
        if (packages.count > 0) {
            contentView.installButton.title = Strings.installNPackages(count: String(packages.count))
            contentView.installButton.isEnabled = true
        } else {
            contentView.installButton.title = Strings.install
            contentView.installButton.isEnabled = false
        }
    }
    
    
    internal lazy var presenter = { UpdatePresenter(view: self) }()
    private var tableDelegate: UpdateTableDelegate! = nil
    
    
    lazy var onSkipButtonPressed: Driver<Void> = {
        return self.contentView.skipButton.rx.tap.asDriver()
    }()
    
    lazy var onInstallButtonPressed: Driver<Void> = {
        return self.contentView.installButton.rx.tap.asDriver()
    }()
    
    lazy var onRemindButtonPressed: Driver<Void> = {
        return self.contentView.remindButton.rx.tap.asDriver()
    }()
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presenter.start().disposed(by: bag)
        
        contentView.installButton.title = Strings.install
        contentView.installButton.isEnabled = false
        contentView.skipButton.title = Strings.skipTheseUpdates
        contentView.remindButton.title = Strings.remindMeLater
        
        contentView.installButton.sizeToFit()
        contentView.skipButton.sizeToFit()
        contentView.remindButton.sizeToFit()
    }
    
    func setPackages(packages: [Package]) {
        self.tableDelegate = UpdateTableDelegate.init(with: packages)
        self.contentView.tableView.dataSource = self.tableDelegate
        self.contentView.tableView.delegate = self.tableDelegate
        self.contentView.tableView.reloadData()
    }
    
}

enum UpdateViewTableColumns: String {
    case name = "name"
    case version = "version"
    
    init?(identifier: NSUserInterfaceItemIdentifier){
        if let value = UpdateViewTableColumns(rawValue: identifier.rawValue) {
            self = value
        } else {
            return nil
        }
    }
}

class UpdateTableDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    private let packages: [Package]
    private let byteCountFormatter = ByteCountFormatter()
    
    fileprivate var selectedPackages = [Package]()
    
    init(with packages:[Package]) {
        self.packages = packages
        
        super.init()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//        guard let tableColumn = tableColumn else { return nil }
//        guard let column = UpdateViewTableColumns(identifier: tableColumn.identifier) else { return nil }
//        let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
//        let package = packages[row]
//        switch column {
//        case .name:
//            let packageName = package.name[Strings.languageCode ?? "en"] ?? ""
//            cell.textField?.stringValue =  packageName
//
//            if let button = cell.nextKeyView as? RxCheckbox {
//                button.set(onToggle: {[weak self] _ in
//                    //TODO: update selected packages
//                    return
//                })
//                if selectedPackages.contains(package) {
//                    button.state = .on
//                } else {
//                    button.state = .off
//                }
//            }
//        case .version:
//            let version = package.version
//            var size: String = self.byteCountFormatter.string(fromByteCount: 0)
//            switch package.installer {
//            case .macOsInstaller(let installer):
//                size = self.byteCountFormatter.string(fromByteCount: Int64(installer.size))
//            default:
//                break
//            }
//            cell.textField?.stringValue = Strings.updateAvailable + ": " + version + " (" + size + ")"
//        }
//
//
//        return cell
        return nil
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return packages.count
    }
    
}
