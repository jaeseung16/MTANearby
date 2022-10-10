//
//  MTATripDescriptor.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/3/22.
//

import Foundation

struct MTATrip: CustomStringConvertible {
    var tripId: String?
    var routeId: String?
    var start: Date?
    var scheduleRelationship: String?
    var assigned: Bool?
    var trainId: String?
    var direction: MTADirection?
    
    var description: String {
        return "MTATrip[tripId=\(String(describing: tripId)), routeId=\(String(describing: routeId)), start=\(String(describing: start)), assigned=\(String(describing: assigned)) trainId=\(String(describing: trainId)), direction=\(String(describing: direction))]"
    }
}
