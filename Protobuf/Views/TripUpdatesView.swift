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
                    Text("\(stopTimeUpdate.id)")
                    
                    Spacer()
                    
                    if let arrivalTime = stopTimeUpdate.arrivalTime {
                        Text(arrivalTime, format: Date.FormatStyle(date: .complete, time: .complete))
                    }
                }
            }
        }
    }
}
