//
//  TrainsAtStopView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/17/22.
//

import SwiftUI

struct TrainsAtStopView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    private let maxAgo: TimeInterval = -1 * 60
    private let maxComing: TimeInterval = 30 * 60
    
    var stop: MTAStop
    var trains: [MTATrain]
    
    var body: some View {
        List {
            ForEach(trains, id: \.self) { train in
                if let trip = train.trip, let arrivalTime = train.arrivalTime, isValid(arrivalTime) {
                    NavigationLink {
                        if let tripId = trip.tripId, let tripUpdate = viewModel.tripUpdatesByTripId[tripId] {
                            TripUpdatesView(tripUpdate: tripUpdate[0])
                        } else {
                            EmptyView()
                        }
                    } label: {
                        HStack {
                            Image(systemName: getDirection(of: train)?.systemName ?? "")
                            
                            ZStack {
                                Circle()
                                    .foregroundColor(getRouteColor(of: trip) ?? .clear)
                                
                                Text(getRouteId(of: trip)?.rawValue ?? "")
                                    .font(.title2)
                                    .foregroundColor(getRouteIdColor(of: trip))
                            }
                            .frame(width: 30, height: 30)
                            
                            //Spacer()
                            
                            //Text("\(train.status?.rawValue ?? "")")
                            
                            //Text("\(train.stopId ?? "")")
                            
                            Spacer()
                            
                            Text(getTimeInterval(arrivalTime))
                                .foregroundColor(arrivalTime < Date() ? .secondary : .primary)
                        }
                    }
                }
            }
        }
    }
    
    private func isValid(_ arrivalTime: Date) -> Bool {
        return arrivalTime.timeIntervalSinceNow > maxAgo && arrivalTime.timeIntervalSinceNow < maxComing
    }
    
    private func getRouteId(of trip: MTATrip) -> MTARouteId? {
        if let tripId = trip.tripId {
            let routeAndDirection = String(tripId.split(separator: "_")[1])
            let route = routeAndDirection.split(separator: ".")[0]
            return MTARouteId(rawValue: String(route))
        } else {
            return nil
        }
    }
    
    private func getRouteColor(of trip: MTATrip) -> Color? {
        if let tripId = trip.tripId {
            let routeAndDirection = String(tripId.split(separator: "_")[1])
            let route = routeAndDirection.split(separator: ".")[0]
            if let routeId = MTARouteId(rawValue: String(route)), let mtaRoute = ViewModel.mtaRoutes.first(where: { $0.id == routeId }) {
                return Color(uiColor: hexStringToUIColor(hex: mtaRoute.color))
            }
        }
        return nil
    }
    
    private func getRouteIdColor(of trip: MTATrip) -> Color {
        switch getRouteId(of: trip) {
        case .n, .q, .r, .w:
            return .black
        default:
            return .white
        }
    }
    
    private func hexStringToUIColor (hex:String) -> UIColor {
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
    
    private func getOriginTime(of trip: MTATrip) -> Date {
        if let tripId = trip.tripId, let timecode = Double(tripId.split(separator: "_")[0]) {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            return Date(timeInterval: timecode / 100.0 * 60.0, since: startOfDay)
        } else {
            return Date()
        }
    }
    
    private func getDirection(of trip: MTATrip) -> MTADirection? {
        if let direction = trip.direction {
            return direction
        } else if let tripId = trip.tripId {
            let routeAndDirection = String(tripId.split(separator: "_")[1])
            let direction = routeAndDirection.split(separator: ".").last ?? ""
            return MTADirection(rawValue: String(direction))
        } else {
            return nil
        }
    }
    
    private func getDirection(of train: MTATrain) -> MTADirection? {
        if let trip = train.trip, let direction = getDirection(of: trip) {
             return direction
        } else if let last = train.stopId?.last {
            if last == "N" {
                return .north
            } else if last == "S" {
                return .south
            }
        }
        return nil
    }
    
    private func getTimeInterval(_ arrivalTime: Date) -> String {
        return RelativeDateTimeFormatter().localizedString(for: arrivalTime, relativeTo: Date())
    }
}

