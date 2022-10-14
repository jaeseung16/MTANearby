//
//  ViewModel.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/12/22.
//

import Foundation
import os
import CodableCSV

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
    
    func getAllData() -> Void {
        MTASubwayFeedURL.allCases.forEach { getData(from: $0) }
    }
    
    func getData(from mtaSubwayFeedURL: MTASubwayFeedURL) -> Void {
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
                    let measured = Date(timeIntervalSince1970: TimeInterval(vehicle.timestamp))
                    
                    ViewModel.logger.info("vehicle = \(String(describing: vehicle), privacy: .public)")
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
                    
                    ViewModel.logger.info("mtaVehicle = \(String(describing: mtaVehicle), privacy: .public)")
                }
                
                if entity.hasTripUpdate {
                    let tripUpdate = entity.tripUpdate
                    
                    ViewModel.logger.info("tripUpdate = \(String(describing: tripUpdate), privacy: .public)")
                    
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
                    
                    ViewModel.logger.info("mtaTripUpdate = \(String(describing: mtaTripUpdate), privacy: .public)")
                    
                }
            }
            
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
    
}
