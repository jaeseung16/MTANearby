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
                            Text("\(trip.trainId ?? "")")
                            
                            Spacer()
                            
                            Text("\(trip.tripId ?? "")")
                            
                            Spacer()
                            
                            Text("\(vehicle.stopSequence ?? UInt.max)")
                            
                            Spacer()
                            
                            Text("\(trip.direction?.rawValue ?? "")")
                            
                            Spacer()
                            
                            Text("\(vehicle.status.rawValue)")
                        }
                    }
                }
            }
        }
    }
}
