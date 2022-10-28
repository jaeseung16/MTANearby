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
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    // 40.7370413,-73.8625352 Home
    // 40.75696,-73.9703863 850 Third Ave
    private var location = CLLocationCoordinate2D(latitude: 40.75696, longitude: -73.9703863)
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.712778, longitude: -74.006111),
                                                   latitudinalMeters: CLLocationDistance(2000),
                                                   longitudinalMeters: CLLocationDistance(2000))
    
    @State private var stops = ViewModel.mtaStops
    @State private var routes = ViewModel.mtaRoutes
    @State private var stopsByRoute = ViewModel.stopsByRoute
    @State private var stopsById = ViewModel.stopsById
    @State private var vehiclesNearby = [MTAStop: [MTAVehicle]]()
    @State private var trainsNearby = [MTAStop: [MTATrain]]()
    @State private var stopsNearby = [MTAStop]()
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    viewModel.getAllData()
                } label: {
                    Text("Download feed data")
                        .padding()
                }
                
                Spacer()
                
                Button {
                    vehiclesNearby = viewModel.vehicles(near: location)
                } label: {
                    Text("Show trains")
                        .padding()
                }
                
                Spacer()
                
                Button {
                    stopsNearby = viewModel.stops(near: location)
                    trainsNearby = viewModel.trains(near: location)
                } label: {
                    Text("Show trains 2")
                        .padding()
                }
                
                Spacer()
            }
            
            if !trainsNearby.isEmpty {
                NavigationView{
                    List {
                        ForEach(stopsNearby, id:\.self) { stop in
                            if let trains = trainsNearby[stop] {
                                NavigationLink {
                                    TrainsAtStopView(stop: stop, trains: trains.filter( {$0.arrivalTime != nil} ).sorted(by: {$0.arrivalTime! < $1.arrivalTime!}))
                                } label: {
                                    HStack {
                                        Text("\(stop.name)")
                                        
                                        Spacer()
                                        
                                        Text(distance(to: stop).converted(to: .miles), format: .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(1))))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            /*
            if !vehiclesNearby.isEmpty {
                NavigationView{
                    List {
                        ForEach(Array(vehiclesNearby.keys), id:\.self) { stop in
                            if let vehicles = vehiclesNearby[stop] {
                                NavigationLink {
                                    VehiclesAtStopView(stop: stop, vehicles: vehicles)
                                } label: {
                                    Text("\(stop.name)")
                                }
                            }
                        }
                    }
                }
            }
            */
            
            /*
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
    
    private func distance(to stop: MTAStop) -> Measurement<UnitLength> {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
        
        return Measurement(value: stopLocation.distance(from: clLocation), unit: UnitLength.meters)
    }
    
}
