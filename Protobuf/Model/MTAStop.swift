//
//  Stop.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/26/22.
//

import Foundation
import CoreLocation

struct MTAStop: Identifiable, Codable, Hashable {
    var id: String
    var code: String
    var name: String
    var desc: String
    var latitude: Double
    var longitude: Double
    var zoneId: String
    var url: String
    var locationType: Int
    var parentStation: String
    
    enum CodingKeys: Int, CodingKey {
        case id = 0
        case code = 1
        case name = 2
        case desc = 3
        case latitude = 4
        case longitude = 5
        case zoneId = 6
        case url = 7
        case locationType = 8
        case parentStation = 9
    }
    
    func getCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func getCLLocation() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
}

