//
//  MTADirection.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/5/22.
//

import Foundation

enum MTADirection {
    case east
    case west
    case south
    case north
    
    init(from direction: NyctTripDescriptor.Direction) {
        switch direction {
        case .north:
            self = .east
        case .south:
            self = .south
        case .east:
            self = .east
        case .west:
            self = .west
        }
    }
}
