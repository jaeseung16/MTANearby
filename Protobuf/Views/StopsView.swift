//
//  StopsView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/10/22.
//

import SwiftUI

struct StopsView: View {
    @EnvironmentObject private var viewModel: ViewModel

    @State var stops: [MTAStop]
    
    var body: some View {
        
        List {
            ForEach(stops) { stop in
                //Text("\(stop.id ?? ""): \(stop.name ?? "")")
                if let key = stop.id {
                    if let vehicles = viewModel.vehiclesByStopId[key] {
                        NavigationLink {
                            VehiclesAtStopView(stop: stop, vehicles: vehicles)
                        } label: {
                            HStack {
                                Text("\(stop.id): \(stop.name)")
                                Spacer()
                                Text("\(stop.latitude), \(stop.longitude)")
                            }
                        }
                    } else {
                        HStack {
                            Text("\(stop.id): \(stop.name)")
                            Spacer()
                            Text("\(stop.latitude), \(stop.longitude)")
                        }
                    }
                }
            }
        }
        
        /*
        NavigationView {
            List {
                ForEach(Array(stopsById.keys).sorted(by: <), id: \.self) { key in
                    if let stop = stopsById[key], let vehicles = vehiclesByStopId[key] {
                        NavigationLink {
                            VehiclesAtStopView(stop: stop, vehicles: vehicles)
                        } label: {
                            HStack {
                                Text("\(key)")
                                Spacer()
                                Text("\(stop.name)")
                            }
                        }
                    } else {
                        HStack {
                            Text("\(key)")
                            Spacer()
                            Text("\(stopsById[key]?.name ?? "")")
                        }
                    }
                }
            }
        }
         */
        
    }
}
