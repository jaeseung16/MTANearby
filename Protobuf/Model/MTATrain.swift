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
    
    func getDirection() -> MTADirection? {
        if let trip = trip, let direction = trip.getDirection() {
             return direction
        } else if let last = stopId?.last {
            if last == "N" {
                return .north
            } else if last == "S" {
                return .south
            }
        }
        return nil
    }
}
