//
//  LocationManager.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 11/23/22.
//

import Foundation
@preconcurrency import CoreLocation
import os
@preconcurrency import MapKit

@MainActor
class LocationHelper {
    private static let logger = Logger()
    
    private static let UNKNOWN = "Unknown"
    
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
    
    func lookUpCurrentLocation() async -> String {
        guard let lastLocation = locationManager.location,
              let request = MKReverseGeocodingRequest(location: lastLocation) else {
            return LocationHelper.UNKNOWN
        }
        do {
            let mapItems = try await request.mapItems
            return mapItems.first?.name ?? LocationHelper.UNKNOWN
        } catch {
            return LocationHelper.UNKNOWN
        }
    }
    
    private func getUserLocality(from placemark: CLPlacemark) -> String {
        let subThoroughfare = placemark.subThoroughfare ?? ""
        let thoroughfare = placemark.thoroughfare ?? ""
        let subLocality = placemark.subLocality ?? ""
        return "\(subThoroughfare) \(thoroughfare) \(subLocality)"
    }
    
}
