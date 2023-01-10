//
//  TimeSettingView.swift
//  WatchMTANearby Watch App
//
//  Created by Jae Seung Lee on 1/10/23.
//

import SwiftUI

struct ArrivalTimeSettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var maxComing: TimeInterval
    
    private let minArrivalTimeInMinute: TimeInterval = 1 * 60
    private let maxArrivalTimeInMinute: TimeInterval = 60 * 60
    
    var body: some View {
        VStack {
            Text("Arrival Time Limit")
                .fontWeight(.bold)
            Text("\(Int(maxComing / 60.0)) minute(s)")
            
            Slider(value: $maxComing, in: minArrivalTimeInMinute...maxArrivalTimeInMinute) {
                Text("Time Limit")
            } minimumValueLabel: {
                Text("1 min")
                    .font(.footnote)
            } maximumValueLabel: {
                Text("1 hour")
                    .font(.footnote)
            }
        }
        .digitalCrownRotation($maxComing, from: minArrivalTimeInMinute, through: maxArrivalTimeInMinute, by: 60, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: false)
    }
}
