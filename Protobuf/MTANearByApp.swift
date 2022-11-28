//
//  ProtobufApp.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/12/22.
//

import SwiftUI

@main
struct MTANearByApp: App {
    @AppStorage("maxDistance") private var maxDistance = 1000.0
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ViewModel(maxDistance))
        }
    }
}
