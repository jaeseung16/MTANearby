//
//  WatchMTANearbyApp.swift
//  WatchMTANearby Watch App
//
//  Created by Jae Seung Lee on 1/10/23.
//

import SwiftUI

@main
struct WatchMTANearby_Watch_AppApp: App {
    @AppStorage("maxDistance") private var maxDistance = 1000.0
    
    private let viewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
