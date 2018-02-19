//
//  CompletionViewable.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-12.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

struct ProcessResult {
    
}

protocol CompletionViewable: class {
    var onRestartButtonTapped: Observable<Void> { get }
    var onFinishButtonTapped: Observable<Void> { get }
    
    func show(errors: [ProcessResult])
    func requiresReboot(is requiresReboot: Bool)
    func showMain()
    func rebootSystem()
}
