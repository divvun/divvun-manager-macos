//
//  AppStore.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-02-18.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation
import RxSwift

enum AppEvent {
    case dontWorryAboutIt
}

struct AppState {
}

class AppStore: RxStore<AppState, AppEvent> {
    static func reducer() -> (AppState, AppEvent) -> AppState {
        return { (state: AppState, event: AppEvent) -> AppState in
            return state
        }
    }
    
    init() {
        super.init(initialState: AppState(), reducers: [AppStore.reducer()])
    }
}
