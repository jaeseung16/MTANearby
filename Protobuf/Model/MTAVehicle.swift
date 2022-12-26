//
//  MTAVehicle.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/8/22.
//

import Foundation

struct MTAVehicle: Hashable {
    let status: MTAVehicleStatus
    let stopId: String?
    let stopSequence: UInt?
    let timestamp: Date?
    let trip: MTATrip?
}
