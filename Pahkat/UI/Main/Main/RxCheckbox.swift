//
//  RxCheckbox.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-20.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class OutlineCheckbox: NSButton {
    var package: Package?
    var group: String?
}

class RxCheckbox: NSButton {
    private(set) var bag: DisposeBag? = nil
    private(set) var toggleCallback: ((NSControl.StateValue) -> ())? = nil
    
    func set(onToggle: @escaping (NSControl.StateValue) -> ()) {
        self.toggleCallback = onToggle
    }
    
    private func createSubscription() {
        bag = DisposeBag()
        
        self.rx.state.skip(1)
            .subscribe(onNext: { [weak self] state in
                print("RxCheckbox:onToggle(\(state)) \(self?.toolTip ?? "OHNO")")
                self?.toggleCallback?(state)
            })
            .disposed(by: bag!)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        print("RxCheckbox:awakeFromNib \(self.toolTip)")
        createSubscription()
    }
    
    override func viewDidUnhide() {
        super.viewDidUnhide()
        print("RxCheckbox:viewDidUnhide \(self.toolTip)")
        createSubscription()
    }


    override func viewDidHide() {
        super.viewDidHide()
        print("RxCheckbox:viewDidHide \(self.toolTip)")
        bag = nil
    }
    
    
    deinit {
        print("RxCheckbox:deinit \(self.toolTip)")
        bag = nil
    }
}
