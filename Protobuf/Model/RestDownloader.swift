//
//  RestDownloader.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 12/25/22.
//

import Foundation
import os
import CoreLocation

class RestDownloader {
    static let logger = Logger()
    
    static let urlString = "http://localhost:8080/mtafeedmonitor/json"
    
    func download(from location: CLLocation?, completionHandler: @escaping (MTAFeedWrapper?, MTAFeedDownloadError?) -> Void) -> Void {
        download(from: location) { result in
            switch result {
            case .success(let feed):
                let mtaFeedWrapper = self.process(feed)
                completionHandler(mtaFeedWrapper, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    private func download(from location: CLLocation?, completionHandler: @escaping (Result<RestResponseWrapper, MTAFeedDownloadError>) -> Void) -> Void {
        
        let url = URL(string: RestDownloader.urlString)!
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpMethod = "POST"
        
        if let location = location {
            urlRequest.httpBody = "longitude=\(location.coordinate.longitude)&latitude=\(location.coordinate.latitude)".data(using: .utf8)!
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            let start = Date()
            //RestDownloader.logger.log("Downloading feeds from mtaSubwayFeedURL = \(url, privacy: .public)")
            //RestDownloader.logger.info("response = \(String(describing: response))")
            //RestDownloader.logger.info("error = \(String(describing: error?.localizedDescription))")
            
            guard let data = data else {
                RestDownloader.logger.log("No data downloaded from mtaSubwayFeedURL = \(url, privacy: .public)")
                completionHandler(.failure(.noData))
                return
            }
            
            //RestDownloader.logger.log("data=\(String(describing: data))")
            
            //let jsonData = try? JSONSerialization.jsonObject(with: data)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            //RestDownloader.logger.log("jsonData=\(String(describing: jsonData))")
            
            var feed: RestResponseWrapper?
            do {
                feed = try decoder.decode(RestResponseWrapper.self, from: data)
            } catch {
                RestDownloader.logger.error("\(error, privacy: .public)")
            }
            
            guard let feed = feed else {
                RestDownloader.logger.error("Cannot parse feed data from \(url, privacy: .public)")
                completionHandler(.failure(.cannotParse))
                return
            }
            
            //RestDownloader.logger.log("feed=\(String(describing: feed), privacy: .public)")
            
            completionHandler(.success(feed))
            RestDownloader.logger.log("For url=\(url.absoluteString), it took \(DateInterval(start: start, end: Date()).duration) sec")
            
        }
        
        task.resume()
        
    }
    
    private func process(_ feed: RestResponseWrapper) -> MTAFeedWrapper {
        var vehiclesByStopId = [String: [MTAVehicle]]()
        var tripUpdatesByTripId = [String: [MTATripUpdate]]()
        
        if let vehicles = feed.vehiclesByTripId {
            vehicles.forEach { tripId, vehicle in
                let status = MTAVehicleStatus(from: vehicle.status)
                let stopId = vehicle.stopId
                let stopSequence = vehicle.stopSequence
                let timestamp = vehicle.timestamp
                
                var mtaTrip: MTATrip?
                if let trip = vehicle.trip {
                    let tripId = trip.tripId
                    let routeId = trip.routeId
                    let start = trip.start
                    let assigned = trip.assigned
                    let trainId = trip.trainId
                    let direction = trip.direction ?? .north
                    
                    mtaTrip = MTATrip(tripId: tripId,
                                          routeId: routeId,
                                          start: start,
                                          assigned: assigned,
                                          trainId: trainId,
                                          direction: MTADirection(from: direction))
                }
                
                let mtaVehicle = MTAVehicle(status: status,
                                            stopId: stopId,
                                            stopSequence: stopSequence,
                                            timestamp: timestamp,
                                            trip: mtaTrip)
                
                if let stopId = stopId {
                    if vehiclesByStopId.keys.contains(stopId) {
                        vehiclesByStopId[stopId]?.append(mtaVehicle)
                    } else {
                        vehiclesByStopId[stopId] = [mtaVehicle]
                    }
                    //RestDownloader.logger.log("stopId=\(stopId, privacy: .public)")
                }
            }
        }
        
        if let tripUpdates = feed.tripUpdatesByTripId {
            tripUpdates.forEach { tripId, tripUpdate in
                var mtaTrip: MTATrip?
                var mtaStopTimeUpdates = [MTAStopTimeUpdate]()
                
                if let trip = tripUpdate.trip {
                    let tripId = trip.tripId
                    let routeId = trip.routeId
                    let start = trip.start
                    let assigned = trip.assigned
                    let trainId = trip.trainId
                    let direction = trip.direction ?? .north
                    
                    mtaTrip = MTATrip(tripId: tripId,
                                          routeId: routeId,
                                          start: start,
                                          assigned: assigned,
                                          trainId: trainId,
                                          direction: MTADirection(from: direction))
                }
                
                tripUpdate.stopTimeUpdates.forEach { stopTimeUpdate in
                    let stopId = stopTimeUpdate.stopId
                    let arrivalTime = stopTimeUpdate.arrivalTime
                    let departureTime = stopTimeUpdate.departureTime
                    let scheduledTrack = stopTimeUpdate.scheduledTrack
                    let actualTrack = stopTimeUpdate.actualTrack
                    
                    let mtaStopTimeUpdate = MTAStopTimeUpdate(stopId: stopId,
                                                              arrivalTime: arrivalTime,
                                                              departureTime: departureTime,
                                                              scheduledTrack: scheduledTrack,
                                                              actualTrack: actualTrack)
                    
                    mtaStopTimeUpdates.append(mtaStopTimeUpdate)
                }
                
                let mtaTripUpdate = MTATripUpdate(trip: mtaTrip, stopTimeUpdates: mtaStopTimeUpdates)
                tripUpdatesByTripId[tripId] = [mtaTripUpdate]
            }
        }
        
        return MTAFeedWrapper(vehiclesByStopId: vehiclesByStopId, tripUpdatesByTripId: tripUpdatesByTripId)
    }
    
}
