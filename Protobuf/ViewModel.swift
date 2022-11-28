//
//  ViewModel.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/12/22.
//

import Foundation
import os
import CodableCSV
import CoreLocation
import MapKit

class ViewModel: NSObject, ObservableObject {
    static let logger = Logger()
    
    static var mtaStops: [MTAStop] {
        guard let stopsURL = Bundle.main.url(forResource: "stops", withExtension: "txt") else {
            ViewModel.logger.error("No file named stops.txt")
            return [MTAStop]()
        }
        
        guard let contents = try? String(contentsOf: stopsURL) else {
            ViewModel.logger.error("The file doesn't contain anything")
            return [MTAStop]()
        }
        
        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
        
        guard let result = try? decoder.decode([MTAStop].self, from: contents) else {
            ViewModel.logger.error("Cannot decode \(stopsURL) to Stop")
            return [MTAStop]()
        }
        
        //ViewModel.logger.info("\(result)")
        
        return result
    }
    
    static var mtaRoutes: [MTARoute] {
        guard let stopsURL = Bundle.main.url(forResource: "routes", withExtension: "txt") else {
            ViewModel.logger.error("No file named routes.txt")
            return [MTARoute]()
        }
        
        guard let contents = try? String(contentsOf: stopsURL) else {
            ViewModel.logger.error("The file doesn't contain anything")
            return [MTARoute]()
        }
        
        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
        
        guard let result = try? decoder.decode([MTARoute].self, from: contents) else {
            ViewModel.logger.error("Cannot decode \(stopsURL) to Stop")
            return [MTARoute]()
        }
        
        //ViewModel.logger.info("\(result)")
        
        return result
    }
    
    static var stopsByRoute: [MTARouteId: [MTAStop]] {
        var result = [MTARouteId: [MTAStop]]()
        
        mtaStops.forEach { stop in
            if let firstLetter = stop.id.first, let routeId = MTARouteId(rawValue: String(firstLetter)) {
                if result[routeId] == nil {
                    result[routeId] = [MTAStop]()
                }
                result[routeId]?.append(stop)
            }
        }
        
        //ViewModel.logger.info("\(result)")
        
        return result
    }
    
    static var stopsById: [String: MTAStop] = Dictionary(uniqueKeysWithValues: mtaStops.map { ($0.id, $0) })
    
    @Published var updated = false
    @Published var numberOfUpdatedFeed = 0
    var maxDistance = 1000.0 {
        didSet {
            if let coordinate = coordinate {
                region = MKCoordinateRegion(center: coordinate,
                                            latitudinalMeters: CLLocationDistance(maxDistance * rangeFactor),
                                            longitudinalMeters: CLLocationDistance(maxDistance * rangeFactor))
            }
        }
    }
    
    var feedDownloader = MTAFeedDownloader()
    
    var vehiclesByStopId = [String: [MTAVehicle]]()
    var tripUpdatesByTripId = [String: [MTATripUpdate]]()
    var tripUpdatesByStopId = [String: [MTATripUpdate]]()
    
    func getAllData() -> Void {
        ViewModel.logger.log("getAllData()")
        if !vehiclesByStopId.isEmpty {
            vehiclesByStopId.removeAll()
        }
        if !tripUpdatesByTripId.isEmpty {
            tripUpdatesByTripId.removeAll()
        }
        if !tripUpdatesByStopId.isEmpty {
            tripUpdatesByStopId.removeAll()
        }
        
        DispatchQueue.main.async {
            self.numberOfUpdatedFeed = 0
        }
        
        MTASubwayFeedURL.allCases.forEach { feedDownloader.download(from: $0) { wrapper, error in
            guard let wrapper = wrapper else {
                ViewModel.logger.log("Failed to download MTA feeds: error = \(String(describing: error?.localizedDescription), privacy: .public)")
                return
            }
            DispatchQueue.main.async {
                //ViewModel.logger.log("wrapper.tripUpdatesByTripId.count = \(wrapper.tripUpdatesByTripId.count, privacy: .public)")
                if !wrapper.tripUpdatesByTripId.isEmpty {
                    wrapper.tripUpdatesByTripId.forEach { key, updates in
                        self.tripUpdatesByTripId[key] = updates
                    }
                }
                //ViewModel.logger.log("wrapper.vehiclesByStopId.count = \(wrapper.vehiclesByStopId.count, privacy: .public)")
                if !wrapper.vehiclesByStopId.isEmpty {
                    wrapper.vehiclesByStopId.forEach { key, vehicles in
                        self.vehiclesByStopId[key] = vehicles
                    }
                }
                self.numberOfUpdatedFeed += 1
            }
            
        } }
    }
    
    func vehicles(within distance: Double, from center: CLLocationCoordinate2D) -> [MTAStop: [MTAVehicle]] {
        var vehicles = [MTAStop: [MTAVehicle]]()
        
        let radius = CLLocationDistance(distance)
        let circularRegion = CLCircularRegion(center: center, radius: radius, identifier: "\(center)")
        
        let stopsNearBy = ViewModel.mtaStops.filter { mtaStop in
            circularRegion.contains(CLLocationCoordinate2D(latitude: mtaStop.latitude, longitude: mtaStop.longitude))
        }
        
        ViewModel.logger.info("stopsNearBy.count = \(String(describing: stopsNearBy.count), privacy: .public) around \(String(describing: center), privacy: .public)")
        
        for stop in stopsNearBy {
            ViewModel.logger.info("stop.id = \(String(describing: stop.id), privacy: .public) around \(String(describing: center), privacy: .public)")
            if let vehiclesAtStop = vehiclesByStopId[stop.id] {
                vehicles[stop] = vehiclesAtStop
            }
        }
        
        //ViewModel.logger.info("vehicles = \(String(describing: vehicles), privacy: .public) around \(String(describing: center), privacy: .public)")
        
        return vehicles
    }
    
    func trains(within distance: Double, from center: CLLocationCoordinate2D) -> [MTAStop: [MTATrain]] {
        var trains = [MTAStop: [MTATrain]]()
        
        let radius = CLLocationDistance(distance)
        let circularRegion = CLCircularRegion(center: center, radius: radius, identifier: "\(center)")
        
        let stopsNearby = ViewModel.mtaStops.filter { mtaStop in
            circularRegion.contains(CLLocationCoordinate2D(latitude: mtaStop.latitude, longitude: mtaStop.longitude))
        }
        
        let stopIds = stopsNearby.map { $0.id }
        
        for tripId in tripUpdatesByTripId.keys {
            if let tripUpdates = tripUpdatesByTripId[tripId] {
                for tripUpdate in tripUpdates {
                    for stopTimeUpdate in tripUpdate.stopTimeUpdates {
                        if let stopId = stopTimeUpdate.stopId, stopIds.contains(stopId) {
                            let vehiclesAtStop = vehiclesByStopId[stopId]?.first(where: { tripId == $0.trip?.tripId })
                            
                            let mtaTrain = MTATrain(trip: tripUpdate.trip,
                                                    status: vehiclesAtStop?.status,
                                                    stopId: stopId,
                                                    arrivalTime: stopTimeUpdate.arrivalTime,
                                                    departureTime: stopTimeUpdate.departureTime)
                            
                            var stopIdWithoutDirection: String
                            if let last = stopId.last, last == "N" || last == "S" {
                                stopIdWithoutDirection = String(stopId.dropLast(1))
                            } else {
                                stopIdWithoutDirection = stopId
                            }
                            
                            if let stop = ViewModel.stopsById[stopIdWithoutDirection], trains[stop] != nil {
                                trains[stop]!.append(mtaTrain)
                            } else if let stop = ViewModel.stopsById[stopIdWithoutDirection], trains[stop] == nil {
                                trains[stop] = Array(arrayLiteral: mtaTrain)
                            } else {
                                ViewModel.logger.info("Can't find a stop with stopId=\(stopId), privacy: .public)")
                            }
                        }
                    }
                }
            }
            
        }
            
        // ViewModel.logger.info("trains=\(trains, privacy: .public) near (\(center.longitude, privacy: .public), \(center.latitude, privacy: .public))")
        
        return trains
    }
    
    func stops(within distance: Double, from center: CLLocationCoordinate2D) -> [MTAStop] {
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let radius = CLLocationDistance(distance)
        let circularRegion = CLCircularRegion(center: center, radius: radius, identifier: "\(center)")
        
        return ViewModel.mtaStops.filter { mtaStop in
            circularRegion.contains(CLLocationCoordinate2D(latitude: mtaStop.latitude, longitude: mtaStop.longitude))
        }.sorted { mtaStop1, mtaStop2 in
            let location1 = CLLocation(latitude: mtaStop1.latitude, longitude: mtaStop1.longitude)
            let location2 = CLLocation(latitude: mtaStop2.latitude, longitude: mtaStop2.longitude)
            
            return location1.distance(from: location) < location2.distance(from: location)
        }
        
    }
    
    // MARK: - LocationManager
    
    let locationManager = LocationManager()
    var userLocality: String = "Unknown"
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var region: MKCoordinateRegion?
    private var rangeFactor = 2.0
    
    var regionSpan: CLLocationDistance {
        return CLLocationDistance(maxDistance * rangeFactor)
    }
    
    func lookUpCurrentLocation() {
        ViewModel.logger.info("lookUpCurrentLocation()")
        userLocality = locationManager.lookUpCurrentLocation()
    }
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        
        if let _ = UserDefaults.standard.object(forKey: "maxDistance") {
            self.maxDistance = UserDefaults.standard.double(forKey: "maxDistance")
        }
    }
    
    convenience init(_ maxDistance: Double) {
        self.init()
        self.maxDistance = maxDistance
    }
    
    func updateRegion(center coordinate: CLLocationCoordinate2D) -> Void {
        region = MKCoordinateRegion(center: coordinate,
                                    latitudinalMeters: CLLocationDistance(maxDistance * rangeFactor),
                                    longitudinalMeters: CLLocationDistance(maxDistance * rangeFactor))
    }
    
}

extension ViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinate = location.coordinate
        
        if let coordinate = coordinate {
            updateRegion(center: coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        ViewModel.logger.log("CLLocationManager: \(error.localizedDescription, privacy: .public)")
    }
}
