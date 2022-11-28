//
//  DistanceUnit.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 11/28/22.
//

import Foundation

enum DistanceUnit: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    
    case km = 0
    case mile = 1
    
    var unitLength: UnitLength {
        switch self {
        case .km:
            return .kilometers
        case .mile:
            return .miles
        }
    }
}
