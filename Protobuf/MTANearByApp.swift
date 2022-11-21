//
//  ProtobufApp.swift
//  Protobuf
//
//  Created by Jae Seung Lee on 9/12/22.
//

import SwiftUI

@main
struct MTANearByApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ViewModel())
        }
    }
}