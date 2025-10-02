//
//  TripUpdatesView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 10/15/22.
//

import SwiftUI

struct TripUpdatesView: View {
    var tripUpdate: MTATripUpdate?
    
    var body: some View {
        if let tripUpdate = tripUpdate {
            List {
                ForEach(tripUpdate.stopTimeUpdates) { stopTimeUpdate in
                    HStack {
                        Text("\(ViewModel.stopsById[stopTimeUpdate.id]?.name ?? stopTimeUpdate.id)")
                        
                        Spacer()
                        
                        if let eventTime = stopTimeUpdate.eventTime {
                            Text(eventTime, style: .time)
                                .foregroundColor(eventTime < Date() ? .secondary : .primary)
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
    
}
