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
    case setRepositories([RepositoryIndex])
}

struct AppState {
    var repositories = [RepositoryIndex]()
}

class AppStore: RxStore<AppState, AppEvent> {
    static func reducer() -> (AppState, AppEvent) -> AppState {
        return { (state: AppState, event: AppEvent) -> AppState in
            var newState = state
            
            switch (event) {
            case let .setRepositories(repos):
                newState.repositories = repos
            }
            
            return newState
        }
    }
    
    init() {
        super.init(initialState: AppState(), reducers: [AppStore.reducer()])
    }
}
