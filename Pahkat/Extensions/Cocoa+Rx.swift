//
//  Cocoa+Rx.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift

class DisposableViewController<V: View>: ViewController<V> {
    internal var bag: DisposeBag! = DisposeBag()
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if bag == nil {
            bag = DisposeBag()
        }
    }
    
    override func viewWillDisappear() {
        bag = nil
        
        super.viewWillDisappear()
    }
}
