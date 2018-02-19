//
//  DownloadPresenter.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

class DownloadPresenter {
    private weak var view: DownloadViewable!
    let packages: [Package]
    
    required init(view: DownloadViewable, packages: [Package]) {
        self.view = view
        self.packages = packages
    }
    
    func start() -> Disposable {
        return Observable<Void>.empty().subscribe()
    }
}
