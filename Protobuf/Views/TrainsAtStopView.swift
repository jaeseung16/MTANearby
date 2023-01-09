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
            Map(coordinateRegion: region, interactionModes: .zoom, showsUserLocation: true, annotationItems: [stop]) { place in
                MapMarker(coordinate: place.getCLLocationCoordinate2D())
            }
            .aspectRatio(CGSize(width: 1.0, height: 1.0), contentMode: .fit)
            
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
                            getLabel(for: train, trip: trip, arrivalTime: eventTime)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func getLabel(for train: MTATrain, trip: MTATrip, arrivalTime: Date) -> some View {
        HStack {
            Image(systemName: train.getDirection()?.systemName ?? "")
            
            getRouteView(for: trip)
                .frame(width: 30, height: 30)
            
            Spacer()
            
            if Date().distance(to: arrivalTime) > 15*60 {
                Text(arrivalTime, style: .time)
                    .foregroundColor(.secondary)
            } else {
                Text(getTimeInterval(arrivalTime))
                    .foregroundColor(arrivalTime < Date() ? .secondary : .primary)
            }
        }
    }
    
    private func getRouteView(for trip: MTATrip) -> some View {
        ZStack {
            Circle()
                .foregroundColor(getRouteColor(of: trip) ?? .clear)
            
            Text(trip.getRouteId()?.rawValue ?? "")
                .font(.title2)
                .foregroundColor(getRouteIdColor(of: trip))
        }
    }
    
    private func isValid(_ eventTime: Date) -> Bool {
        return eventTime.timeIntervalSinceNow > viewModel.maxAgo && eventTime.timeIntervalSinceNow < viewModel.maxComing
    }
    
    private func getRouteColor(of trip: MTATrip) -> Color? {
        if let routeId = trip.getRouteId(), let mtaRoute = ViewModel.mtaRoutes.first(where: { $0.id == routeId }) {
            return Color(uiColor: hexStringToUIColor(mtaRoute.color))
        }
        return nil
    }
    
    private func getRouteIdColor(of trip: MTATrip) -> Color {
        switch trip.getRouteId() {
        case .n, .q, .r, .w:
            return .black
        default:
            return .white
        }
    }
    
    private func hexStringToUIColor(_ hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    private func getTimeInterval(_ arrivalTime: Date) -> String {
        return RelativeDateTimeFormatter().localizedString(for: arrivalTime, relativeTo: Date())
    }
}

