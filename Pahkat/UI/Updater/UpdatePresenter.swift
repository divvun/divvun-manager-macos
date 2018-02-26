//
//  UpdatePresenter.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class UpdatePresenter {
    private weak var view: UpdateViewable!
    
    required init(view: UpdateViewable) {
        self.view = view
    }
    
    func start() -> Disposable {
        return CompositeDisposable(disposables: [
            
            ])
    }
}
