//
//  MainPresenter.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-06.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class MainPresenter {
    private weak var view: MainViewable?
    
    init(view: MainViewable) {
        self.view = view
    }
    
    func start() -> Disposable {
        guard let view = view else { return Disposables.create() }
        
        view.update(title: "Hello!")
        
        return view.onPrimaryButtonPressed.drive(onNext: {
            print("Button pressed!")
        }, onCompleted: nil, onDisposed: nil)
    }
}
