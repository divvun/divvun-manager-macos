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
    case setRepository(RepositoryIndex)
}

struct AppState {
    var repository: RepositoryIndex? = nil
}

class AppStore: RxStore<AppState, AppEvent> {
    func reducer(state: AppState, event: AppEvent) -> AppState {
        var newState = state
        
        switch (event) {
        case let .setRepository(repo):
            newState.repository = repo
        }
        
        return newState
    }
    
    init() {
        super.init(initialState: AppState(), reducers: [self.reducer])
    }
}
