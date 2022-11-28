//
//  DistanceSettingView.swift
//  MTANearby
//
//  Created by Jae Seung Lee on 11/28/22.
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
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                Text("Max Distance")
                    .font(.title3)
                
                HStack {
                    Spacer()
                    List {
                        Picker("Unit", selection: $distanceUnit) {
                            Text("kilometers").tag(DistanceUnit.km)
                            Text("miles").tag(DistanceUnit.mile)
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 100)
                    Spacer()
                }
                
                Slider(value: $distance, in: minDistance...maxDistance) {
                    Text("Maximum Distance")
                } minimumValueLabel: {
                    if kmSelected {
                        distanceText(minDistance, distanceUnit: .km)
                    } else {
                        distanceText(minDistance, distanceUnit: .mile)
                    }
                } maximumValueLabel: {
                    if kmSelected {
                        distanceText(maxDistance, distanceUnit: .km)
                    } else {
                        distanceText(maxDistance, distanceUnit: .mile)
                    }
                }
                .frame(maxWidth: 0.9 * geometry.size.width)
                
                HStack {
                    Text("Maximum Distance: ")
                    distanceText(distance, distanceUnit: distanceUnit)
                }
                .frame(maxHeight: 100)
                
                Button("Done") {
                    dismiss()
                }
                
                Spacer()
            }
        }
        
    }
    
    private func distanceText(_ distance: Double, distanceUnit: DistanceUnit) -> Text {
        Text(Measurement(value: distance, unit: UnitLength.meters).converted(to: distanceUnit.unitLength), format: distanceFormatStyle)
    }
}

