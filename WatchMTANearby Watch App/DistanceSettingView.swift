//
//  DistanceSettingView.swift
//  WatchMTANearby Watch App
//
//  Created by Jae Seung Lee on 1/10/23.
//

import SwiftUI

struct DistanceSettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var distanceUnit: DistanceUnit
    @Binding var distance: Double
    
    private var distanceFormatStyle: Measurement<UnitLength>.FormatStyle {
        .measurement(width: .abbreviated,
                     usage: .asProvided,
                     numberFormatStyle: .number.precision(.fractionLength(1)))
    }
    
    private let minDistance: Double = 100
    private let maxDistance: Double = 3000
    private var kmSelected: Bool {
        distanceUnit == .km
    }
    
    var body: some View {
        VStack {
            Text("Distance Limit")
                .fontWeight(.bold)
            
            if kmSelected {
                distanceText(distance, distanceUnit: .km)
            } else {
                distanceText(distance, distanceUnit: .mile)
            }
            
            Slider(value: $distance, in: minDistance...maxDistance) {
                Text("Distance Limit")
            } minimumValueLabel: {
                if kmSelected {
                    distanceText(minDistance, distanceUnit: .km)
                        .font(.footnote)
                } else {
                    distanceText(minDistance, distanceUnit: .mile)
                        .font(.footnote)
                }
            } maximumValueLabel: {
                if kmSelected {
                    distanceText(maxDistance, distanceUnit: .km)
                        .font(.footnote)
                } else {
                    distanceText(maxDistance, distanceUnit: .mile)
                        .font(.footnote)
                }
            }
            
            Picker("Unit", selection: $distanceUnit) {
                Text("kilometers").tag(DistanceUnit.km)
                Text("miles").tag(DistanceUnit.mile)
            }
        }
        .digitalCrownRotation($distance, from: minDistance, through: maxDistance, by: 0.01, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: false)
    }
    
    private func distanceText(_ distance: Double, distanceUnit: DistanceUnit) -> Text {
        Text(Measurement(value: distance, unit: UnitLength.meters).converted(to: distanceUnit.unitLength), format: distanceFormatStyle)
    }
}

