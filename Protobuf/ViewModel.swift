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

@MainActor
class ViewModel: NSObject, ObservableObject {
    private static let logger = Logger()
    
    static let mtaStops: [MTAStop] = ViewModel.read(from: "stops", type: MTAStop.self)
    
    static let mtaRoutes: [MTARoute] = ViewModel.read(from: "routes", type: MTARoute.self)
        
    private static func read<T>(from resource: String, type: T.Type) -> [T] where T: Decodable {
        guard let stopsURL = Bundle.main.url(forResource: resource, withExtension: "txt") else {
            ViewModel.logger.error("No file named \(resource).txt")
            return [T]()
        }
        
        guard let contents = try? String(contentsOf: stopsURL, encoding: .utf8) else {
            ViewModel.logger.error("The file doesn't contain anything")
            return [T]()
        }
        
        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
        
        guard let result = try? decoder.decode([T].self, from: contents) else {
            ViewModel.logger.error("Cannot decode \(stopsURL) to Stop")
            return [T]()
        }
        
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
    
    static let stopsById: [String: MTAStop] = Dictionary(uniqueKeysWithValues: mtaStops.map { ($0.id, $0) })
    
    @Published var feedAvailable = true
    @Published var numberOfUpdatedFeed = 0
    var maxDistance = 1000.0 {
        didSet {
            if let coordinate = self.location?.coordinate {
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
    
    func getAllData() async -> Bool {
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
        return await downloadAll()
    }
    
    private func downloadAll() async -> Bool {
        numberOfUpdatedFeed = 0
        for mtaSubwayFeedURL in MTASubwayFeedURL.allCases {
            do {
                let wrapper = try await feedDownloader.download(from: mtaSubwayFeedURL)
                
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
                ViewModel.logger.log("numberOfUpdatedFeed=\(self.numberOfUpdatedFeed, privacy: .public)")
                
            } catch {
                ViewModel.logger.log("Failed to download MTA feeds from \(mtaSubwayFeedURL.rawValue): error = \(String(describing: error.localizedDescription), privacy: .public)")
            }
        }
        return numberOfUpdatedFeed > 0
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
        //ViewModel.logger.info("stopIds=\(stopIds, privacy: .public)")
        //ViewModel.logger.info("tripUpdatesByTripId=\(self.tripUpdatesByTripId, privacy: .public)")
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
    
    let locationHelper = LocationHelper()
    var userLocality: String = "Unknown"
    @Published var userLocalityUpdated = false
    @Published var locationUpdated = false
    var location: CLLocation?
    var region: MKCoordinateRegion?
    private var rangeFactor = 2.0
    
    var regionSpan: CLLocationDistance {
        return CLLocationDistance(maxDistance * rangeFactor)
    }
    
    func lookUpCurrentLocation() async {
        self.userLocality = await locationHelper.lookUpCurrentLocation()
        self.userLocalityUpdated.toggle()
    }
    
    var maxAgo: TimeInterval = -1 * 60
    var maxComing: TimeInterval = 30 * 60
    
    override init() {
        super.init()
        
        locationHelper.delegate = self
        
        if let _ = UserDefaults.standard.object(forKey: "maxDistance") {
            self.maxDistance = UserDefaults.standard.double(forKey: "maxDistance")
        }
        
        if let _ = UserDefaults.standard.object(forKey: "maxComing") {
            self.maxComing = UserDefaults.standard.double(forKey: "maxComing")
        }
        
        Task {
            self.feedAvailable = await getAllData()
        }
    }
    
    func updateRegion(center coordinate: CLLocationCoordinate2D) -> Void {
        region = MKCoordinateRegion(center: coordinate,
                                    latitudinalMeters: CLLocationDistance(maxDistance * rangeFactor),
                                    longitudinalMeters: CLLocationDistance(maxDistance * rangeFactor))
    }
    
}

extension ViewModel: @MainActor CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        self.location = location
        self.locationUpdated.toggle()
        
        if let location = self.location {
            Task {
                await lookUpCurrentLocation()
                updateRegion(center: location.coordinate)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        ViewModel.logger.log("didFailWithError: error = \(error.localizedDescription, privacy: .public)")
        location = nil
    }
}

