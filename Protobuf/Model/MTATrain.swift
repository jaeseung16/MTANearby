//
//  MTATrain.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/17/22.
//

import Foundation

struct MTATrain: Hashable {
    let trip: MTATrip?
    let status: MTAVehicleStatus?
    
    let stopId: String?
    let arrivalTime: Date?
    let departureTime: Date?
}
