//
//  LandingViewController.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2019-02-07.
//  Copyright © 2019 Divvun. All rights reserved.
//

import Cocoa
import WebKit
import RxSwift

class LandingViewController: DisposableViewController<LandingView>, NSToolbarDelegate, WebBridgeViewable {
    private lazy var bridge = { WebBridgeService(webView: self.contentView.webView, view: self) }()
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "settings":
            let item = NSToolbarItem(view: contentView.settingsButton, identifier: itemIdentifier)
            item.maxSize = NSSize(width: CGFloat(48.0), height: item.maxSize.height)
            return item
        case "button":
            contentView.primaryButton.sizeToFit()
            return NSToolbarItem(view: contentView.primaryButton, identifier: itemIdentifier)
        case "title":
            contentView.primaryLabel.sizeToFit()
            return NSToolbarItem(view: contentView.primaryLabel, identifier: itemIdentifier)
        default:
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureToolbar()
    }
    
    struct RepoHolder {
        let value: LoadedRepository?
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        AppContext.settings.selectedRepository
            .map { url -> RepoHolder in
                // Convert url into loaded repository or fail
                return RepoHolder(value: nil)
            }.subscribe(onNext: { [weak self] holder in
                if let repo = holder.value {
                    if let url = repo.index.landingURL {
                        self?.bridge.start(url: url)
                    } else {
                        // Show a view saying that this repo has no landing page, and to go to detailed view.
                    }
                } else {
                    // Show a view saying no selection.
                }
            }).disposed(by: bag)
        
        contentView.primaryButton.rx.tap.subscribe(onNext: { _ in
            AppContext.windows.show(MainWindowController.self, viewController: MainViewController(), sender: self)
        }).disposed(by: bag)
    }
    
    private func configureToolbar() {
        let window = AppContext.windows.get(MainWindowController.self).contentWindow
        
        window.titleVisibility = .hidden
        window.toolbar!.isVisible = true
        window.toolbar!.delegate = self
        
        let toolbarItems = ["settings",
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "title",
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            NSToolbarItem.Identifier.flexibleSpace.rawValue,
                            "button"]
        
        window.toolbar!.setItems(toolbarItems)
    }
    
    func handle(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = Strings.downloadError
            alert.informativeText = String(describing: error)
            
            alert.alertStyle = .critical
            log.error(error)
            alert.runModal()
            
            self.contentView.webView.reload()
        }
    }
}
