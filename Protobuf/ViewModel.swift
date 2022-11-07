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
        
        ViewModel.logger.info("\(result)")
        
        return result
    }
    
    static var stopsById: [String: MTAStop] = Dictionary(uniqueKeysWithValues: mtaStops.map { ($0.id, $0) })
    
    @Published var updated = false
    @Published var numberOfUpdatedFeed = 0
    
    var vehiclesByStopId = [String: [MTAVehicle]]()
    var tripUpdatesByTripId = [String: [MTATripUpdate]]()
    var tripUpdatesByStopId = [String: [MTATripUpdate]]()
    
    func getAllData() -> Void {
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
   
        MTASubwayFeedURL.allCases.forEach { getData(from: $0) }
    }
    
    func getData(from mtaSubwayFeedURL: MTASubwayFeedURL) -> Void {
        let start = Date()
        
        let url = mtaSubwayFeedURL.url()!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("v8NSHelLz0aMJi8Dpdlhw1FowwMvjszO1YCNCg6x", forHTTPHeaderField: "x-api-key")

        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            ViewModel.logger.log("mtaSubwayFeedURL = \(mtaSubwayFeedURL.rawValue, privacy: .public)")
            //ViewModel.logger.info("response = \(String(describing: response))")
            //ViewModel.logger.info("error = \(String(describing: error?.localizedDescription))")
            
            guard let data = data else {
                return
            }
            
            //ViewModel.logger.log("data = \(String(describing: data))")
            
            let feed = try? TransitRealtime_FeedMessage(serializedData: data, extensions: Nyct_u45Subway_Extensions)
            
            guard let feed = feed else {
                ViewModel.logger.error("Cannot parse feed for \(url)")
                return
            }
            
            if feed.hasHeader {
                let header = feed.header
                ViewModel.logger.log("\(header.debugDescription)")
                
                //let timestamp = Date(timeIntervalSince1970: TimeInterval(header.timestamp))
                
                var mtaTripReplacementPeriods = [MTATripReplacementPeriod]()
                
                if header.hasNyctFeedHeader {
                    let nyctFeedHeader = header.nyctFeedHeader
                    ViewModel.logger.log("\(String(describing: nyctFeedHeader), privacy: .public)")
                    
                    nyctFeedHeader.tripReplacementPeriod.forEach { period in
                        let routeId = period.hasRouteID ? period.routeID : nil
                        let replacementPeriod = period.hasReplacementPeriod ? period.replacementPeriod : nil
                        
                        let endTime = (replacementPeriod?.hasEnd ?? false) ? Date(timeIntervalSince1970: TimeInterval(replacementPeriod!.end)) : nil
                        
                        let mtaTripReplacementPeriod = MTATripReplacementPeriod(routeId: routeId, endTime: endTime)
                        
                        mtaTripReplacementPeriods.append(mtaTripReplacementPeriod)
                    }
                    
                }
                ViewModel.logger.log("\(String(describing: mtaTripReplacementPeriods), privacy: .public)")
            }
            
            let date = Date(timeIntervalSince1970: TimeInterval(feed.header.timestamp))
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .current
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .medium
            
            ViewModel.logger.log("date = \(dateFormatter.string(from: date))")
            
            var vehicles = [MTAVehicle]()
            var tripUpdates = [MTATripUpdate]()
            
            feed.entity.forEach { entity in
                
                if entity.hasAlert {
                    let alert = entity.alert
                    
                    let headerText = alert.headerText.translation.first?.text ?? "No Header Text"
                    
                    let trips = self.process(alert: alert)
                    
                    let mtaAlert = MTAAlert(delayedTrips: trips, headerText: headerText, date: date)
                    
                    ViewModel.logger.log("mtaAlert = \(String(describing: mtaAlert), privacy: .public)")
                }
                
                if entity.hasVehicle {
                    let vehicle = entity.vehicle
                    //let measured = Date(timeIntervalSince1970: TimeInterval(vehicle.timestamp))
                    
                    //ViewModel.logger.info("vehicle = \(String(describing: vehicle), privacy: .public)")
                    //ViewModel.logger.info("date = \(dateFormatter.string(from: measured))")
                    
                    // https://developers.google.com/transit/gtfs-realtime/reference#message-vehicleposition
                    let status = vehicle.hasCurrentStatus ? MTAVehicleStatus(from: vehicle.currentStatus) : .inTransitTo
                    let stopSequence = vehicle.hasCurrentStopSequence ? UInt(vehicle.currentStopSequence) : nil
                    let stopId = vehicle.hasStopID ? vehicle.stopID : nil
                    let trip = vehicle.hasTrip ? self.getMTATrip(from: vehicle.trip) : nil
                    let date = vehicle.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(vehicle.timestamp)) : Date()
                    
                    let mtaVehicle = MTAVehicle(status: status,
                                             stopId: stopId,
                                             stopSequence: stopSequence,
                                             timestamp: date,
                                             trip: trip)
                    
                    vehicles.append(mtaVehicle)
                    
                    //ViewModel.logger.info("mtaVehicle = \(String(describing: mtaVehicle), privacy: .public)")
                }
                
                if entity.hasTripUpdate {
                    let tripUpdate = entity.tripUpdate
                    
                    //ViewModel.logger.info("tripUpdate = \(String(describing: tripUpdate), privacy: .public)")
                    
                    var trip: MTATrip?
                    if tripUpdate.hasTrip {
                        trip = self.getMTATrip(from: tripUpdate.trip)
                    }
                    
                    var mtaStopTimeUpdates = [MTAStopTimeUpdate]()
                    
                    tripUpdate.stopTimeUpdate.forEach { update in
                        
                        let stopId = update.hasStopID ? update.stopID : nil
                        let arrivalTime = update.hasArrival ? Date(timeIntervalSince1970: TimeInterval(update.arrival.time)) : nil
                        let departureTime = update.hasDeparture ? Date(timeIntervalSince1970: TimeInterval(update.departure.time)) : nil
                        
                        let nyctStopTimeUpdate = update.hasNyctStopTimeUpdate ? update.nyctStopTimeUpdate : nil
                        
                        let scheduledTrack = (nyctStopTimeUpdate?.hasScheduledTrack ?? false) ? nyctStopTimeUpdate?.scheduledTrack : nil
                        let actualTrack = (nyctStopTimeUpdate?.hasActualTrack ?? false) ? nyctStopTimeUpdate?.actualTrack : nil
                        
                        let mtaStopTimeUpdate = MTAStopTimeUpdate(stopId: stopId,
                                                                  arrivalTime: arrivalTime,
                                                                  departureTime: departureTime,
                                                                  scheduledTrack: scheduledTrack,
                                                                  actualTrack: actualTrack)
                        
                        mtaStopTimeUpdates.append(mtaStopTimeUpdate)
                        
                    }
                    
                    let mtaTripUpdate = MTATripUpdate(trip: trip, stopTimeUpdates: mtaStopTimeUpdates)
                    
                    //ViewModel.logger.info("mtaTripUpdate = \(String(describing: mtaTripUpdate), privacy: .public)")
                    
                    tripUpdates.append(mtaTripUpdate)
                }
            }
            
            ViewModel.logger.info("vehicles.count = \(String(describing: vehicles.count), privacy: .public)")
            
            if !vehicles.isEmpty {
                for vehicle in vehicles {
                    //ViewModel.logger.info("vehicle = \(String(describing: vehicle), privacy: .public)")
                    if let stopId = vehicle.stopId {
                        if self.vehiclesByStopId.keys.contains(stopId) {
                            self.vehiclesByStopId[stopId]?.append(vehicle)
                        } else {
                            self.vehiclesByStopId[stopId] = [vehicle]
                        }
                    }
                }
            }
            
            if !tripUpdates.isEmpty {
                for tripUpdate in tripUpdates {
                    ViewModel.logger.info("tripUpdate = \(String(describing: tripUpdate), privacy: .public)")
                    if let tripId = tripUpdate.trip?.tripId {
                        if self.tripUpdatesByTripId.keys.contains(tripId) {
                            self.tripUpdatesByTripId[tripId]?.append(tripUpdate)
                        } else {
                            self.tripUpdatesByTripId[tripId] = [tripUpdate]
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.numberOfUpdatedFeed += 1
            }
            
            ViewModel.logger.log("For url=\(url.absoluteString), it took \(DateInterval(start: start, end: Date()).duration) sec")
        
        }

        task.resume()
    }
    
    private func process(alert: TransitRealtime_Alert) -> [MTATrip] {
        //ViewModel.logger.log("alert = \(alert.debugDescription, privacy: .public)")
        
        var trips = [MTATrip]()
        alert.informedEntity.forEach { entity in
            if entity.hasTrip {
                let trip = entity.trip
                
                if trip.hasNyctTripDescriptor {
                    //ViewModel.logger.log("nyctTripDescriptor = \(trip.nyctTripDescriptor.debugDescription, privacy: .public)")
                    
                    let nyctTrip = trip.nyctTripDescriptor
                    
                    let mtaTrip = MTATrip(tripId: trip.tripID,
                                          routeId: trip.routeID,
                                          trainId: nyctTrip.trainID,
                                          direction: MTADirection(from: nyctTrip.direction))
                    
                    trips.append(mtaTrip)
                }
                
            }
        }
        
        return trips
    }
    
    private func getMTATrip(from trip: TransitRealtime_TripDescriptor) -> MTATrip {
        let nyctTrip = trip.nyctTripDescriptor
        
        let tripId = trip.hasTripID ? trip.tripID : nil
        let routeId = trip.hasRouteID ? trip.routeID : nil
        let trainId = nyctTrip.hasTrainID ? nyctTrip.trainID : nil
        let direction = nyctTrip.hasDirection ? MTADirection(from: nyctTrip.direction) : nil
        let assigned = nyctTrip.hasIsAssigned ? nyctTrip.isAssigned : nil
        
        let startDate = trip.hasStartDate ? trip.startDate : nil
        let startTime = trip.hasStartTime ? trip.startTime : nil
        
        let dateFormatter = DateFormatter()
        //dateFormatter.locale = Locale(identifier: "en_US")
        //dateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMdd HH:mm:ss")
        dateFormatter.dateFormat = "yyyyMMdd HH:mm:ss"
        
        var start: Date?
        if startDate != nil && startTime != nil {
            start = dateFormatter.date(from: "\(startDate!) \(startTime!)")
            ViewModel.logger.info("start = \(String(describing: start), privacy: .public) from \(startDate!) \(startTime!)")
        } else if startDate != nil {
            // TODO: start time from tripId?
            
        }
        
        return MTATrip(tripId: tripId,
                       routeId: routeId,
                       start: start,
                       assigned: assigned,
                       trainId: trainId,
                       direction: direction)
    }
    
    func vehicles(near center: CLLocationCoordinate2D) -> [MTAStop: [MTAVehicle]] {
        var vehicles = [MTAStop: [MTAVehicle]]()
        
        let radius = CLLocationDistance(2000)
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
    
    func trains(near center: CLLocationCoordinate2D) -> [MTAStop: [MTATrain]] {
        var trains = [MTAStop: [MTATrain]]()
        
        let radius = CLLocationDistance(1500)
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
    
    func stops(near center: CLLocationCoordinate2D) -> [MTAStop] {
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let radius = CLLocationDistance(1500)
        let circularRegion = CLCircularRegion(center: center, radius: radius, identifier: "\(center)")
        
        return ViewModel.mtaStops.filter { mtaStop in
            circularRegion.contains(CLLocationCoordinate2D(latitude: mtaStop.latitude, longitude: mtaStop.longitude))
        }.sorted { mtaStop1, mtaStop2 in
            let location1 = CLLocation(latitude: mtaStop1.latitude, longitude: mtaStop1.longitude)
            let location2 = CLLocation(latitude: mtaStop2.latitude, longitude: mtaStop2.longitude)
            
            return location1.distance(from: location) < location2.distance(from: location)
        }
        
    }
}
