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
    @AppStorage("maxComing") private var maxComing: TimeInterval = 30 * 60
    
    private var distanceFormatStyle: Measurement<UnitLength>.FormatStyle {
        .measurement(width: .abbreviated,
                     usage: .asProvided,
                     numberFormatStyle: .number.precision(.fractionLength(1)))
    }
    
    @State private var location = CLLocationCoordinate2D(latitude: 40.712778, longitude: -74.006111) // NYC City Hall
    
    @State private var trainsNearby = [MTAStop: [MTATrain]]()
    @State private var stopsNearby = [MTAStop]()
    @State private var lastRefresh = Date()
    @State private var userLocality = "Unknown"
    
    @State private var showProgress = false
    @State private var presentUpdateMaxDistance = false
    @State private var presentAlertLocationUnkown = false
    @State private var presentAlertFeedUnavailable = false
    @State private var presentAlertNotInNYC = false
    @State private var presentedAlertNotInNYC = false
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @State private var refreshable = false
    
    @State private var selectedStop: MTAStop? = nil
    @State private var selectedTrain: MTATrain? = nil
    
    private var kmSelected: Bool {
        distanceUnit == .km
    }
    
    var body: some View {
        VStack {
            NavigationSplitView {
                VStack {
                    locationLabel
                    
                    if !trainsNearby.isEmpty {
                        List(selection: $selectedStop) {
                            ForEach(stopsNearby, id:\.self) { stop in
                                if getTrains(at: stop) != nil {
                                    NavigationLink(value: stop) {
                                        label(for: stop, distanceUnit: kmSelected ? .km : .mile)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    bottomView
                }
            } content: {
                if let selectedStop = selectedStop, let trains = getTrains(at: selectedStop) {
                    TrainsAtStopView(stop: selectedStop,
                                     trains: getSortedTrains(from: trains),
                                     tripUpdateByTripId: getTripUpdateByTripId(from: trains),
                                     selectedTrain: $selectedTrain)
                    .navigationTitle(selectedStop.name)
                }
            } detail: {
                if let selectedTrain = selectedTrain {
                    TripUpdatesView(tripUpdate: getTripUpdate(for: selectedTrain))
                }
            }
        }
        .padding()
        .overlay {
            ProgressView("Please wait...")
                .progressViewStyle(.circular)
                .opacity(showProgress ? 1 : 0)
        }
        .sheet(isPresented: $presentUpdateMaxDistance) {
            SettingsView(distanceUnit: $distanceUnit, distance: $maxDistance, maxComing: $maxComing)
        }
        .onReceive(viewModel.$numberOfUpdatedFeed) { newValue in
            if newValue == MTASubwayFeedURL.allCases.count {
                showProgress = false
            }
            if viewModel.location != nil {
                updateStopsAndTrainsNearby()
            }
        }
        .onReceive(viewModel.$locationUpdated) { _ in
            updateStopsAndTrainsNearby()
        }
        .onReceive(viewModel.$userLocalityUpdated) { _ in
            userLocality = viewModel.userLocality
        }
        .onReceive(viewModel.$feedAvailable) { _ in
            presentAlertFeedUnavailable = !viewModel.feedAvailable
        }
        .onReceive(timer) { _ in
            refreshable = lastRefresh.distance(to: Date()) > 60
        }
        .onChange(of: maxComing) { _, newValue in
            viewModel.maxComing = newValue
        }
        .onChange(of: presentUpdateMaxDistance) { _, _ in
            if viewModel.maxDistance != maxDistance {
                viewModel.maxDistance = maxDistance
                updateStopsAndTrainsNearby()
            }
        }
        .alert(Text("Can't determine your current location"), isPresented: $presentAlertLocationUnkown) {
            Button("OK") {
                
            }
        }
        .alert(Text("Can't access MTA feed"), isPresented: $presentAlertFeedUnavailable) {
            Button("OK") {
                
            }
        }
        .alert(Text("There are no nearby subway stations"), isPresented: $presentAlertNotInNYC) {
            Button("OK") {
                presentedAlertNotInNYC = true
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
    
    private var bottomView: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    presentUpdateMaxDistance = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                
                Spacer()

                Button {
                    downloadAllDataByButton()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                .disabled(!refreshable)
                
                Spacer()
            }
            .disabled(showProgress)
            
            HStack {
                Spacer()
                Text("Refreshed:")
                Text(lastRefresh, style: .time)
            }
            
            #if os(iOS)
            BannerAd()
                .frame(height: 50)
            #endif
        }
    }
    
    private func label(for stop: MTAStop, distanceUnit: DistanceUnit) -> some View {
        HStack {
            Text("\(stop.name)")
            
            Spacer()
            
            Text(distance(to: stop).converted(to: distanceUnit.unitLength), format: distanceFormatStyle)
        }
    }
    
    private func distance(to stop: MTAStop) -> Measurement<UnitLength> {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let stopLocation = stop.getCLLocation()
        return Measurement(value: stopLocation.distance(from: clLocation), unit: UnitLength.meters)
    }
    
    private func downloadAllDataByButton() -> Void {
        refreshable = false
        if !showProgress {
            showProgress = true
            downloadAllData()
        }
    }
    
    private func downloadAllData() -> Void {
        lastRefresh = Date()
        if (viewModel.location?.coordinate) != nil {
            Task {
                let success = await viewModel.getAllData()
                
                if success {
                    presentAlertFeedUnavailable = false
                } else {
                    presentAlertFeedUnavailable.toggle()
                }
                showProgress = false
            }
        } else if showProgress {
            presentAlertLocationUnkown.toggle()
            showProgress = false
        }
    }
    
    
    private func getTrains(at stop: MTAStop) -> [MTATrain]? {
        return trainsNearby[stop]?.filter { $0.eventTime != nil }
    }
    
    private func getSortedTrains(from trains: [MTATrain]) -> [MTATrain] {
        return trains.sorted(by: { $0.eventTime! < $1.eventTime! })
    }
    
    private func getTripUpdateByTripId(from trains: [MTATrain]) -> [String: MTATripUpdate] {
        var result = [String: MTATripUpdate]()
        for train in trains {
            if let trip = train.trip, let tripId = trip.tripId, let tripUpdates = viewModel.tripUpdatesByTripId[tripId], !tripUpdates.isEmpty {
                result[tripId] = tripUpdates[0]
            }
        }
        return result
    }
    
    private func getTripUpdate(for train: MTATrain) -> MTATripUpdate? {
        if let tripId = train.trip?.tripId, let tripUpdates = viewModel.tripUpdatesByTripId[tripId] {
            return tripUpdates.first
        }
        return nil
    }
    
    private func updateStopsAndTrainsNearby() -> Void {
        if let coordinate = viewModel.location?.coordinate {
            location = coordinate
            stopsNearby = viewModel.stops(within: maxDistance, from: location)
            trainsNearby = viewModel.trains(within: maxDistance, from: location)
            
            if stopsNearby.isEmpty {
                presentAlertNotInNYC = !presentedAlertNotInNYC
            } else if presentedAlertNotInNYC {
                presentedAlertNotInNYC = false
            }
        }
    }
    
}
