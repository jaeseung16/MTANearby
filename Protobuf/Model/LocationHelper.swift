//
//  LocationManager.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 11/23/22.
//

import Foundation
import CoreLocation
import os

class LocationHelper {
    static let logger = Logger()
    
    let locationManager = CLLocationManager()
    
    var delegate: CLLocationManagerDelegate? {
        didSet {
            locationManager.delegate = delegate
            locationManager.startUpdatingLocation()
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    init() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func lookUpCurrentLocation(completionHandler: @escaping (String) -> Void) -> Void {
        if let lastLocation = locationManager.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(lastLocation) { (placemarks, error) in
                var userLocality = "Unknown"
                if error == nil, let placemark = placemarks?[0] {
                    userLocality = "\(placemark.subThoroughfare ?? "") \(placemark.thoroughfare ?? "") \(placemark.subLocality ?? "")"
                }
                completionHandler(userLocality)
            }
        }
    }
    
}
