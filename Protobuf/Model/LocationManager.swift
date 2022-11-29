//
//  LocationManager.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 11/23/22.
//

import Foundation
import CoreLocation
import os

class LocationManager {
    static let logger = Logger()
    
    let locationManager = CLLocationManager()
    
    var delegate: CLLocationManagerDelegate? {
        didSet {
            locationManager.delegate = delegate
            locationManager.requestLocation()
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    init() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func lookUpCurrentLocation() -> String {
        locationManager.requestLocation()
        var userLocality = "Unknown"
        if let lastLocation = locationManager.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(lastLocation) { (placemarks, error) in
                if error == nil, let placemark = placemarks?[0] {
                    userLocality = "\(placemark.subThoroughfare ?? "") \(placemark.thoroughfare ?? "") \(placemark.subLocality ?? "")"
                } else {
                    userLocality = "Unknown"
                }
            }
        }
        LocationManager.logger.log("Returning userLocality=\(userLocality, privacy: .public)")
        return userLocality
    }
    
}
