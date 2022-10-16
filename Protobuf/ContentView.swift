//
//  ContentView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/12/22.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.712778, longitude: -74.006111),
                                                   span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.2))
    
    @State private var stops = ViewModel.mtaStops
    @State private var routes = ViewModel.mtaRoutes
    @State private var stopsByRoute = ViewModel.stopsByRoute
    @State private var stopsById = ViewModel.stopsById
    
    var body: some View {
        Button {
            viewModel.getAllData()
        } label: {
            Text("Download feed data")
                .padding()
        }
        
        NavigationView {
            List {
                ForEach(MTARouteId.allCases) { routeId in
                    if let stops = stopsByRoute[routeId] {
                        NavigationLink {
                            StopsView(stops: stops)
                        } label: {
                            HStack {
                                Text(routeId.rawValue)
                            }
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
        .onChange(of: viewModel.updated) { _ in
            vehiclesByStopId = viewModel.vehiclesByStopId
        }
        
        */
        /*
        List {
            ForEach(routes) { route in
                HStack {
                    Text("\(route.shortName): \(route.longName)")
                }
            }
        }
        */
        /*
        List {
            ForEach(stops) { stop in
                HStack {
                    Text("\(stop.id): \(stop.name)")
                    Spacer()
                    Text("\(stop.latitude), \(stop.longitude)")
                }
                
            }
        }
         */
        
        /*
        Map(coordinateRegion: $region)
            .edgesIgnoringSafeArea(.all)
        */
        /*
            Map(coordinateRegion: $region, annotationItems: stops) { stop in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) {
                    Image(systemName: "m.square.fill")
                        .foregroundColor(.blue)
                }
            }
        */
        
    }
    
}
