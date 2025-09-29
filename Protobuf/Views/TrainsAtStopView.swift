//
//  TrainsAtStopView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/17/22.
//

import SwiftUI
import MapKit

struct TrainsAtStopView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    var stop: MTAStop
    var trains: [MTATrain]
    var tripUpdateByTripId: [String: MTATripUpdate]
    
    private var region : Binding<MKCoordinateRegion> {
        Binding {
            viewModel.region ?? MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.712778, longitude: -74.006111),
                                                   latitudinalMeters: viewModel.regionSpan,
                                                   longitudinalMeters: viewModel.regionSpan)
        } set: { region in
            DispatchQueue.main.async {
                viewModel.region = region
            }
        }
    }
    
    var body: some View {
        VStack {
            if #available(iOS 17.0, *) {
                MapReader { proxy in
                    Map(
                        initialPosition: .region(
                            viewModel.region ?? MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 40.712778, longitude: -74.006111),
                                latitudinalMeters: viewModel.regionSpan,
                                longitudinalMeters: viewModel.regionSpan
                            )
                        ),
                        interactionModes: .zoom
                    ) {
                        UserAnnotation()
                        Marker("", coordinate: stop.getCLLocationCoordinate2D())
                    }
                    .onMapCameraChange { context in
                        let region = context.region
                        DispatchQueue.main.async {
                            viewModel.region = region
                        }
                    }
                }
                .aspectRatio(CGSize(width: 1.0, height: 1.0), contentMode: .fit)
            } else {
                Map(coordinateRegion: region, interactionModes: .zoom, showsUserLocation: true, annotationItems: [stop]) { place in
                    MapMarker(coordinate: place.getCLLocationCoordinate2D())
                }
                .aspectRatio(CGSize(width: 1.0, height: 1.0), contentMode: .fit)
            }
            
            List {
                ForEach(trains, id: \.self) { train in
                    if let trip = train.trip, let eventTime = train.eventTime, isValid(eventTime) {
                        NavigationLink {
                            if let tripId = trip.tripId, let tripUpdate = tripUpdateByTripId[tripId] {
                                TripUpdatesView(tripUpdate: tripUpdate)
                                    .navigationTitle(trip.getRouteId()?.rawValue ?? "")
                            } else {
                                EmptyView()
                            }
                        } label: {
                            label(for: train, trip: trip, arrivalTime: eventTime)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func label(for train: MTATrain, trip: MTATrip, arrivalTime: Date) -> some View {
        HStack {
            Image(systemName: train.getDirection()?.systemName ?? "")
            
            RouteLabel(trip: trip)
                .frame(width: 30, height: 30)
            
            Spacer()
            
            if Date().distance(to: arrivalTime) > 15*60 {
                Text(arrivalTime, style: .time)
                    .foregroundColor(.secondary)
            } else {
                Text(timeInterval(to: arrivalTime))
                    .foregroundColor(arrivalTime < Date() ? .secondary : .primary)
            }
        }
    }
    
    private func isValid(_ eventTime: Date) -> Bool {
        return eventTime.timeIntervalSinceNow > viewModel.maxAgo && eventTime.timeIntervalSinceNow < viewModel.maxComing
    }
    
    private func timeInterval(to arrivalTime: Date) -> String {
        return RelativeDateTimeFormatter().localizedString(for: arrivalTime, relativeTo: Date())
    }
}

