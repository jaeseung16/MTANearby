//
//  WatchTrainsAtStopView.swift
//  WatchMTANearby Watch App
//
//  Created by Jae Seung Lee on 1/10/23.
//

import SwiftUI
import MapKit

struct WatchTrainsAtStopView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    var stop: MTAStop
    var trains: [MTATrain]
    
    var body: some View {
        VStack {
            List {
                ForEach(trains, id: \.self) { train in
                    if let trip = train.trip, let eventTime = train.eventTime, isValid(eventTime) {
                        label(for: train, trip: trip, arrivalTime: eventTime)
                    }
                }
            }
            .listStyle(.plain)
            
            Spacer()
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    private func label(for train: MTATrain, trip: MTATrip, arrivalTime: Date) -> some View {
        HStack {
            Image(systemName: train.getDirection()?.systemName ?? "")
                .resizable()
                .frame(width: 24, height: 24)
            
            WatchRouteLabel(trip: trip)
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
