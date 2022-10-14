//
//  MTARouteId.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/10/22.
//

import Foundation

enum MTARouteId: String, Codable, CaseIterable, Identifiable {
    var id: Self { self }
    
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case fiveX = "5X"
    case six = "6"
    case sixX = "6X"
    case seven = "7"
    case sevenX = "7X"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case fX = "FX"
    case g = "G"
    case j = "J"
    case l = "L"
    case m = "M"
    case n = "N"
    case q = "Q"
    case r = "R"
    case w = "W"
    case z = "Z"
    
    case h = "H"
    case gs = "GS"
    case fs = "FS"
    case si = "SI"
    
}
