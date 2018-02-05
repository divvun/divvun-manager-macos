//
//  Extensions.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-05.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Cocoa
import RxSwift

infix operator =>

func =>(lhs: Disposable, rhs: DisposeBag) {
    lhs.disposed(by: rhs)
}

func +=(lhs: DisposeBag, rhs: Disposable) {
    lhs.insert(rhs)
}

