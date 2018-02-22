//
//  CompletionViewController.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-19.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class CompletionViewController: DisposableViewController<CompletionView>, CompletionViewable {
//        
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    
    var onRestartButtonTapped: Observable<Void> = Observable.empty()
    var onFinishButtonTapped: Observable<Void> = Observable.empty()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(errors: [ProcessResult]) {
    
    }
    
    func requiresReboot(is requiresReboot: Bool) {
        
    }
    
    func showMain() {
        
    }
    
    func rebootSystem() {
        
    }
    
    
}
