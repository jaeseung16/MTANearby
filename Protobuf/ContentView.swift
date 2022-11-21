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
    @State private var location = CLLocationCoordinate2D(latitude: 40.7370413, longitude: -73.8625352)
    
    @State private var stops = ViewModel.mtaStops
    @State private var routes = ViewModel.mtaRoutes
    @State private var stopsByRoute = ViewModel.stopsByRoute
    @State private var stopsById = ViewModel.stopsById
    @State private var vehiclesNearby = [MTAStop: [MTAVehicle]]()
    @State private var trainsNearby = [MTAStop: [MTATrain]]()
    @State private var stopsNearby = [MTAStop]()
    
    @State private var showProgress = true
    
    var body: some View {
        VStack {
            if !viewModel.userLocality.isEmpty && viewModel.userLocality != "Unknown" {
                Label(viewModel.userLocality, systemImage: "mappin.and.ellipse")
            } else {
                Label("Nearby Subway Stations", systemImage: "tram.fill.tunnel")
            }
            
            if !trainsNearby.isEmpty {
                NavigationView {
                    List {
                        ForEach(stopsNearby, id:\.self) { stop in
                            if let trains = trainsNearby[stop] {
                                NavigationLink {
                                    TrainsAtStopView(stop: stop,
                                                     trains: trains.filter( {$0.arrivalTime != nil} ).sorted(by: {$0.arrivalTime! < $1.arrivalTime!}),
                                                     region: MKCoordinateRegion(center: location,
                                                                                latitudinalMeters: CLLocationDistance(3000),
                                                                                longitudinalMeters: CLLocationDistance(3000)))
                                        .navigationTitle(stop.name)
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
            
            Spacer()
            
            Button {
                showProgress = true
                lookUpCurrentLocationAndDownloadAllData()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise.circle")
            }
            .disabled(showProgress)
        }
        .padding()
        .overlay {
            ProgressView("Please wait...")
                .progressViewStyle(CircularProgressViewStyle())
                .opacity(showProgress ? 1 : 0)
        }
        .onReceive(viewModel.$numberOfUpdatedFeed) { newValue in
            if newValue == MTASubwayFeedURL.allCases.count {
                showProgress = false
            }
            stopsNearby = viewModel.stops(near: location)
            trainsNearby = viewModel.trains(near: location)
        }
        .onReceive(viewModel.$coordinate) { newValue in
            lookUpCurrentLocationAndDownloadAllData()
        }
        
    }
    
    private func distance(to stop: MTAStop) -> Measurement<UnitLength> {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
        
        return Measurement(value: stopLocation.distance(from: clLocation), unit: UnitLength.meters)
    }
    
    private func lookUpCurrentLocationAndDownloadAllData() -> Void {
        viewModel.lookUpCurrentLocation()
        if let coordinate =  viewModel.locationManager.location?.coordinate {
            location = coordinate
            viewModel.getAllData()
        }
    }
    
}
