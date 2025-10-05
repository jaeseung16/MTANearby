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
                if let vehicles = viewModel.vehiclesByStopId[stop.id] {
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
}
