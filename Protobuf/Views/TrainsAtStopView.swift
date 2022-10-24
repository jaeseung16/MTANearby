//
//  TrainsAtStopView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/17/22.
//

import SwiftUI

struct TrainsAtStopView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    private let maxTimeInterval: TimeInterval = 30 * 60
    
    var stop: MTAStop
    var trains: [MTATrain]
    
    var body: some View {
        List {
            ForEach(trains, id: \.self) { train in
                if let trip = train.trip, let arrivalTime = train.arrivalTime, arrivalTime.timeIntervalSince(Date()) < maxTimeInterval {
                    NavigationLink {
                        if let tripId = trip.tripId, let tripUpdate = viewModel.tripUpdatesByTripId[tripId] {
                            TripUpdatesView(tripUpdate: tripUpdate[0])
                        } else {
                            EmptyView()
                        }
                    } label: {
                        HStack {
                            // Text("\(trip.tripId ?? "")")
                            
                            Text("Route: \(getRouteId(of: trip))")
                            
                            // Text("\(getOriginTime(of: trip), format: Date.FormatStyle(date: .numeric, time: .standard))")
                            
                            // Text("\(vehicle.stopSequence ?? UInt.max)")
                            
                            Spacer()
                            
                            Text("Direction: \(getDirection(of: trip))")
                            
                            Spacer()
                            
                            Text("Status: \(train.status?.rawValue ?? "")")
                            
                            Spacer()
                            
                            Text(train.arrivalTime ?? Date(), format: Date.FormatStyle(date: .omitted, time: .standard))
                        }
                    }
                }
            }
        }
    }
    
    private func getRouteId(of trip: MTATrip) -> String {
        if let tripId = trip.tripId {
            let routeAndDirection = String(tripId.split(separator: "_")[1])
            let route = routeAndDirection.split(separator: ".")[0]
            return MTARouteId(rawValue: String(route))?.rawValue ?? ""
        } else {
            return ""
        }
    }
    
    private func getOriginTime(of trip: MTATrip) -> Date {
        if let tripId = trip.tripId, let timecode = Double(tripId.split(separator: "_")[0]) {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            return Date(timeInterval: timecode / 100.0 * 60.0, since: startOfDay)
        } else {
            return Date()
        }
    }
    
    private func getDirection(of trip: MTATrip) -> String {
        if let direction = trip.direction {
            return direction.rawValue
        } else if let tripId = trip.tripId {
            let routeAndDirection = String(tripId.split(separator: "_")[1])
            let direction = routeAndDirection.split(separator: ".").last ?? ""
            return MTADirection(rawValue: String(direction))?.rawValue ?? ""
        } else {
            return ""
        }
        
    }
}

