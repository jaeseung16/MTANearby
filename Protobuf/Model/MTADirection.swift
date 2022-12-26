//
//  MTADirection.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/5/22.
//

import Foundation

enum MTADirection: String, Codable {
    case east = "E"
    case west = "W"
    case south = "S"
    case north = "N"
    
    init(from direction: NyctTripDescriptor.Direction) {
        switch direction {
        case .north:
            self = .north
        case .south:
            self = .south
        case .east:
            self = .east
        case .west:
            self = .west
        }
    }
    
    init(from direction: RestDirection) {
        switch direction {
        case .north:
            self = .north
        case .south:
            self = .south
        case .east:
            self = .east
        case .west:
            self = .west
        }
    }
    
    var systemName: String {
        switch self {
        case .north:
            return "arrow.up"
        case .south:
            return "arrow.down"
        case .east:
            return "arrow.right"
        case .west:
            return "arrow.left"
        }
    }
}
