//
//  ContentView.swift
//  WatchMTANearby Watch App
//
//  Created by Jae Seung Lee on 1/10/23.
//

import SwiftUI

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
    @State private var presentUpdateMaxArrivalTime = false
    @State private var presentAlertLocationUnkown = false
    @State private var presentAlertFeedUnavailable = false
    @State private var presentAlertNotInNYC = false
    @State private var presentedAlertNotInNYC = false
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @State private var refreshable = false
    
    private var kmSelected: Bool {
        distanceUnit == .km
    }
    
    var body: some View {
        VStack {
            if !trainsNearby.isEmpty {
                    List {
                        ForEach(stopsNearby, id:\.self) { stop in
                            if let trains = getTrains(at: stop) {
                                NavigationLink {
                                    WatchTrainsAtStopView(stop: stop, trains: getSortedTrains(from: trains))
                                        .environmentObject(viewModel)
                                        .navigationTitle(stop.name)
                                } label: {
                                    if kmSelected {
                                        label(for: stop, distanceUnit: .km)
                                    } else {
                                        label(for: stop, distanceUnit: .mile)
                                    }
                                }
                            }
                        }
                    }
            } else {
                ProgressView("Please wait...")
                    .progressViewStyle(.circular)
                    .opacity(showProgress ? 1 : 0)
                Spacer()
            }
            
            Divider()
            
            bottomView
            
            Divider()
        }
        .padding(1.0)
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $presentUpdateMaxDistance) {
            DistanceSettingView(distanceUnit: $distanceUnit, distance: $maxDistance)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Dismiss") {
                            presentUpdateMaxDistance = false
                        }
                    }
                }
        }
        .sheet(isPresented: $presentUpdateMaxArrivalTime) {
            ArrivalTimeSettingView(maxComing: $maxComing)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Dismiss") {
                            presentUpdateMaxArrivalTime = false
                        }
                    }
                }
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
        .onChange(of: maxComing) { _ in
            if viewModel.maxComing != maxComing {
                viewModel.maxComing = maxComing
            }
        }
        .onChange(of: maxDistance) { _ in
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
    
    private var locationTitle: Text {
        Text("\(!userLocality.isEmpty && userLocality != "Unknown" ? userLocality : "Nearby Subway Stations")")
            .font(.caption2)
    }
    
    private var bottomView: some View {
        VStack {
            HStack {
                Spacer()
                Spacer()
                
                Button {
                    presentUpdateMaxDistance = true
                } label: {
                    Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0, height: 20.0)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    presentUpdateMaxArrivalTime = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0, height: 20.0)
                }
                .buttonStyle(.plain)
                
                Spacer()

                Button {
                    downloadAllDataByButton()
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0, height: 20.0)
                }
                .buttonStyle(.plain)
                .disabled(!refreshable)
                
                Spacer()
                Spacer()
            }
            .disabled(showProgress)
            .frame(height: 30.0)
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
            viewModel.getAllData() { result in
                switch result {
                case .success(let success):
                    presentAlertFeedUnavailable = !success
                case .failure:
                    presentAlertFeedUnavailable.toggle()
                }
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

