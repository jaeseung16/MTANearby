//
//  MTATripUpdate.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/9/22.
//

import Foundation

struct MTATripUpdate {
    let trip: MTATrip?
    let stopTimeUpdates: [MTAStopTimeUpdate]
}
