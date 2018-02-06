//
//  AppDelegate.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var instance: AppDelegate!
    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
        NSApp.mainMenu = NSMenu.loadFromNib(path: "MainMenu")
        
        let mgr = WindowManager()
        
        mgr.show(MainWindowController.self)
//        let w = WindowController<MainWindow>()
//        window = w.contentWindow
//        w.showWindow(nil)
        
        let pahkatApi = PahkatApiService(baseURL: URL(string: "http://localhost:8000")!)
        pahkatApi.repositoryIndex().subscribe(onSuccess: {
            print($0)
        }, onError: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

class App: NSApplication {
    private let appDelegate = AppDelegate()
    
    override init() {
        super.init()
        
        self.delegate = appDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
