//
//  VehiclesAtStopView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/14/22.
//

import SwiftUI

struct VehiclesAtStopView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    var stop: MTAStop
    var vehicles: [MTAVehicle]
    
    var body: some View {
        List {
            ForEach(vehicles, id: \.self) { vehicle in
                if let trip = vehicle.trip {
                    NavigationLink {
                        if let tripId = trip.tripId, let tripUpdate = viewModel.tripUpdatesByTripId[tripId] {
                            TripUpdatesView(tripUpdate: tripUpdate[0])
                        } else {
                            EmptyView()
                        }
                    } label: {
                        HStack {
                            Text("Route: \(getRouteId(of: trip))")
                            
                            Spacer()
                            
                            Text("Direction: \(getDirection(of: trip))")
                            
                            Spacer()
                            
                            Text("Status: \(vehicle.status.rawValue)")
                            
                            Spacer()
                            
                            Text(vehicle.timestamp ?? Date(), format: Date.FormatStyle(date: .omitted, time: .standard))
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
