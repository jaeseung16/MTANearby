//
//  MTAFeedDownloadError.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 12/31/22.
//

import Foundation

enum MTAFeedDownloadError: Error {
    case noURL
    case noData
    case cannotParse
}
