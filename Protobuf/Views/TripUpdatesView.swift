//
//  TripUpdatesView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/15/22.
//

import SwiftUI

struct TripUpdatesView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    @State var tripUpdate: MTATripUpdate
    
    var body: some View {
        List {
            ForEach(tripUpdate.stopTimeUpdates) { stopTimeUpdate in
                HStack {
                    Text("\(ViewModel.stopsById[stopTimeUpdate.id]?.name ?? stopTimeUpdate.id)")
                    
                    Spacer()
                    
                    if let arrivalTime = stopTimeUpdate.arrivalTime {
                        Text(getTimeInterval(arrivalTime))
                            .foregroundColor(arrivalTime < Date() ? .secondary : .primary)
                    }
                }
            }
        }
    }
    
    private func getTimeInterval(_ arrivalTime: Date) -> String {
        return RelativeDateTimeFormatter().localizedString(for: arrivalTime, relativeTo: Date())
    }
}
