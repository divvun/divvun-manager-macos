//
//  MainViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class MainViewController: DisposableViewController<MainView>, MainViewable {
    
    private lazy var presenter = { MainPresenter(view: self) }()
    private var repo: RepositoryIndex? = nil
    
    var onPackageToggled: Observable<Package> = Observable.empty()
    var onGroupToggled: Observable<[Package]> = Observable.empty()
    
    lazy var onPrimaryButtonPressed: Driver<Void> = {
        return self.contentView.primaryButton.rx.tap.asDriver()
    }()
    
    func setRepository(repo: RepositoryIndex) {
        //print(repo)
        self.repo = repo
        contentView.outlineView.delegate = MainViewControllerViewDelegate.init()
        contentView.outlineView.dataSource = MainViewControllerDataSource.init(withRepo: repo)
        //contentView.outlineView.reloadData()
    }
    
    func update(title: String) {
        self.title = title
    }
    
    func showDownloadView(with packages: [Package]) {
        AppContext.windows.set(DownloadViewController(packages: packages), for: MainWindowController.self)
    }
    
    func updatePrimaryButton(isEnabled: Bool, label: String) {
        contentView.primaryButton.isEnabled = isEnabled
        contentView.primaryButton.title = label
    }
    
    func handle(error: Error) {
        print(error)
        // TODO: show errors in a meaningful way to the user
        fatalError("Not implemented")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presenter.start().disposed(by: bag)
    }
    
    
    // OUTLINE VIEW DATA SOURCE
    
    
    
    
}

class MainViewControllerDataSource: NSObject, NSOutlineViewDataSource {
    
    //private let repo: RepositoryIndex
    
    private let data: [String: [Package]]
    
    init(withRepo repo:RepositoryIndex) {
        var data = [String: [Package]]()
        repo.packages.values.forEach({
            if !data.keys.contains($0.category) {
                data[$0.category] = []
            }
            
            data[$0.category]!.append($0)
        })
        
        self.data = data
        
        super.init()
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? String {
            return data[item]!.count
        } else if item as? Package != nil {
            return 0
        } else {
            return data.keys.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if (item as? Package) != nil {
            return true
        } else {
            return true
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? String {
            return data[item]!
        } else {
            return Array(data.keys)[index] //TODO: Make it sane
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        switch tableColumn!.identifier {
        case NSUserInterfaceItemIdentifier("name"):
            if let package = item as? Package {
                return package.name
            } else {
                return item
            }
        case NSUserInterfaceItemIdentifier("version"):
            if let package = item as? Package {
                return package.version
            } else {
                return nil
            }
        case NSUserInterfaceItemIdentifier("state"):
            if let package = item as? Package {
                return nil //TODO: Check state
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

class MainViewControllerViewDelegate: NSObject, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        guard let column = tableColumn else {return nil}
        let cell = outlineView.makeView(withIdentifier: column.identifier, owner: self) as! NSTableCellView
        
        switch column.identifier {
        case NSUserInterfaceItemIdentifier("name"):
            if let package = item as? Package {
                cell.textField?.stringValue = package.name[Strings.languageCode ?? "en"] ?? ""
            } else if let item = item as? String {
                cell.textField?.stringValue =  item
            }
        case NSUserInterfaceItemIdentifier("version"):
            if let package = item as? Package {
                cell.textField?.stringValue = package.version
            } else {
                return nil
            }
        case NSUserInterfaceItemIdentifier("state"):
            if let package = item as? Package {
                return nil //TODO: Check state
            } else {
                return nil
            }
        default:
            return nil
        }
        
        return cell
    }
}
