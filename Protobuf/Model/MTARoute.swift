//
//  MTARoute.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/3/22.
//

import Foundation

struct MTARoute: Identifiable, Codable, Hashable {
    var id: MTARouteId
    var agency: String
    var shortName: String
    var longName: String
    var description: String
    var type: String
    var url: String
    var color: String
    var textColor: String
    
    enum CodingKeys: Int, CodingKey {
        case id = 0
        case agency = 1
        case shortName = 2
        case longName = 3
        case description = 4
        case type = 5
        case url = 6
        case color = 7
        case textColor = 8
    }
}
