//
//  ContentView.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/12/22.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: ViewModel
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.712778, longitude: -74.006111),
                                                   span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.2))
    
    @State private var stops = ViewModel.mtaStops
    @State private var routes = ViewModel.mtaRoutes
    
    var body: some View {
        Button {
            viewModel.getAllData()
        } label: {
            Text("Download feed data")
                .padding()
        }

        /*
        Map(coordinateRegion: $region)
            .edgesIgnoringSafeArea(.all)
        */
        /*
            Map(coordinateRegion: $region, annotationItems: stops) { stop in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) {
                    Image(systemName: "m.square.fill")
                        .foregroundColor(.blue)
                }
            }
        */
        
    }
    
}
