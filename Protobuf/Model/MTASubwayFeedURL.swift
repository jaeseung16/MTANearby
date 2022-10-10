//
//  MTASubwayFeedURL.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/3/22.
//

import Foundation

enum MTASubwayFeedURL: String, CaseIterable {
    private static let urlPrefix = "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs"
    
    case blue = "-ace"
    case orange = "-bdfm"
    case lightGreen = "-g"
    case brown = "-jz"
    case yellow = "-nqrw"
    case gray = "-l"
    case redGreenPurple = ""
    case statenIsland = "-si"
    
    func url() -> URL? {
        return URL(string: MTASubwayFeedURL.urlPrefix + self.rawValue)
    }
    
}
