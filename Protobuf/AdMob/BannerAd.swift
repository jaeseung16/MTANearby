//
//  BannerAd.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 2/9/22.
//

import Foundation
import SwiftUI

struct BannerAd: UIViewControllerRepresentable {
    // For testing, check the demo ad unit ID in https://developers.google.com/admob/ios/test-ads
    let adUnitId = "ca-app-pub-6771077591139198~9875428007"
        
    init() {
    }
    
    func makeUIViewController(context: Context) -> BannerAdViewController {
        return BannerAdViewController(adUnitId: adUnitId)
    }

    func updateUIViewController(_ uiViewController: BannerAdViewController, context: Context) {
        
    }
}
