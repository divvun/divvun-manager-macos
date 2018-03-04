//
//  RPCService+Admin.swift
//  Pahkat
//
//  Created by Brendan Molloy on 2018-03-04.
//  Copyright © 2018 Divvun. All rights reserved.
//

import Foundation

extension PahkatRPCService {
    public convenience init?(requiresAdmin: Bool) {
        if requiresAdmin {
            self.init(service: AdminSubprocess(PahkatRPCService.pahkatcPath.path, arguments: ["ipc"]))
        } else {
            self.init(service: BufferedStringSubprocess(
                PahkatRPCService.pahkatcPath.path,
                arguments: ["ipc"],
                qos: QualityOfService.userInteractive))
        }
    }
}
