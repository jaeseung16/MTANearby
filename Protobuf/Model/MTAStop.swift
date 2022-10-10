//
//  Stop.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/26/22.
//

import Foundation

struct MTAStop: Identifiable, Codable {
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
    
    
}

