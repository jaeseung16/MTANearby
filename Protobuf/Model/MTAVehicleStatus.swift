//
//  MTAVehicleStatus.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/8/22.
//

import Foundation

enum MTAVehicleStatus {
    case incomingAt
    case stoppedAt
    case inTransitTo
    
    init(from direction: TransitRealtime_VehiclePosition.VehicleStopStatus) {
        switch direction {
        case .incomingAt:
            self = .incomingAt
        case .stoppedAt:
            self = .stoppedAt
        case .inTransitTo:
            self = .inTransitTo
        }
    }
}
