//
//  MTAFeedWrapper.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 11/25/22.
//

import Foundation

struct MTAFeedWrapper {
    var vehiclesByStopId = [String: [MTAVehicle]]()
    var tripUpdatesByTripId = [String: [MTATripUpdate]]()
}
