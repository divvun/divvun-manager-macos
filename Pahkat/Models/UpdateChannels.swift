//
//  UpdateChannels.swift
//  Pahkat
//
//  Created by Anton Malmquist on 2018-02-23.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

enum UpdateChannels: String {
    case stable
    case alpha
    case beta
    case nightly
    
    var description: String {
        switch(self) {
        //TODO localise
        case .stable:
            return self.rawValue
        case .alpha:
            return self.rawValue
        case .beta:
            return self.rawValue
        case .nightly:
            return self.rawValue
        }
    }
    
}
