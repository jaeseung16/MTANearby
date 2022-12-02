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
    @AppStorage("maxDistance") private var maxDistance = 1000.0
    @AppStorage("distanceUnit") private var distanceUnit = DistanceUnit.mile
    
    private var distanceFormatStyle: Measurement<UnitLength>.FormatStyle {
        .measurement(width: .abbreviated,
                     usage: .asProvided,
                     numberFormatStyle: .number.precision(.fractionLength(1)))
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
    @State private var lastRefresh = Date()
    @State private var userLocality = "Unknown"
    
    @State private var showProgress = false
    @State private var presentUpdateMaxDistance = false
    @State private var presentAlert = false
    
    var body: some View {
        VStack {
            locationLabel
            
            if !trainsNearby.isEmpty {
                NavigationView {
                    List {
                        ForEach(stopsNearby, id:\.self) { stop in
                            if let trains = trainsNearby[stop] {
                                NavigationLink {
                                    TrainsAtStopView(stop: stop,
                                                     trains: getTrains(from: trains),
                                                     tripUpdateByTripId: getTripUpdateByTripId(from: trains))
                                        .navigationTitle(stop.name)
                                } label: {
                                    label(for: stop)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button {
                    presentUpdateMaxDistance = true
                } label: {
                    Label("Max Distance", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                }
                
                Spacer()

                Button {
                    viewModel.lookUpCurrentLocation()
                    downloadAllDataByButton()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                
                Spacer()
            }
            .disabled(showProgress)
            
            HStack {
                Spacer()
                Text("Refreshed:")
                Text(lastRefresh, style: .time)
            }
        }
        .padding()
        .overlay {
            ProgressView("Please wait...")
                .progressViewStyle(.circular)
                .opacity(showProgress ? 1 : 0)
        }
        .sheet(isPresented: $presentUpdateMaxDistance, content: {
            DistanceSettingView(distanceUnit: $distanceUnit, distance: $maxDistance)
        })
        .onReceive(viewModel.$numberOfUpdatedFeed) { newValue in
            if newValue == MTASubwayFeedURL.allCases.count {
                showProgress = false
            }
            stopsNearby = viewModel.stops(within: maxDistance, from: location)
            trainsNearby = viewModel.trains(within: maxDistance, from: location)
        }
        .onReceive(viewModel.$locationUpdated) { _ in
            downloadAllData()
        }
        .onReceive(viewModel.$userLocalityUpdated) { _ in
            userLocality = viewModel.userLocality
        }
        .onChange(of: presentUpdateMaxDistance) { _ in
            if viewModel.maxDistance != maxDistance {
                viewModel.maxDistance = maxDistance
                stopsNearby = viewModel.stops(within: maxDistance, from: location)
                trainsNearby = viewModel.trains(within: maxDistance, from: location)
            }
        }
        .alert(Text("Can't determine your current location"), isPresented: $presentAlert) {
            Button("OK") {
                
            }
        }
        
    }
    
    private var locationLabel: some View {
        if !userLocality.isEmpty && userLocality != "Unknown" {
            return Label(userLocality, systemImage: "mappin.and.ellipse")
        } else {
            return Label("Nearby Subway Stations", systemImage: "tram.fill.tunnel")
        }
    }
    
    private func label(for stop: MTAStop) -> some View {
        HStack {
            Text("\(stop.name)")
            
            Spacer()
            
            Text(distance(to: stop).converted(to: .miles), format: distanceFormatStyle)
        }
    }
    
    private func distance(to stop: MTAStop) -> Measurement<UnitLength> {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let stopLocation = stop.getCLLocation()
        return Measurement(value: stopLocation.distance(from: clLocation), unit: UnitLength.meters)
    }
    
    private func downloadAllDataByButton() -> Void {
        if !showProgress {
            showProgress = true
            downloadAllData()
        }
    }
    
    private func downloadAllData() -> Void {
        lastRefresh = Date()
        if let coordinate = viewModel.location?.coordinate {
            location = coordinate
            viewModel.getAllData()
        } else if showProgress {
            presentAlert.toggle()
            showProgress = false
        }
    }
    
    private func getTrains(from trains: [MTATrain]) -> [MTATrain] {
        return trains.filter { $0.arrivalTime != nil}
            .sorted(by: {$0.arrivalTime! < $1.arrivalTime!})
    }
    
    private func getTripUpdateByTripId(from trains: [MTATrain]) -> [String: MTATripUpdate] {
        var result = [String: MTATripUpdate]()
        for train in getTrains(from: trains) {
            if let trip = train.trip, let tripId = trip.tripId, let tripUpdates = viewModel.tripUpdatesByTripId[tripId], !tripUpdates.isEmpty {
                result[tripId] = tripUpdates[0]
            }
        }
        return result
    }
    
}
