//
//  WatchRouteLabel.swift
//  WatchMTANearby Watch App
//
//  Created by Jae Seung Lee on 1/10/23.
//

import SwiftUI

struct WatchRouteLabel: View {
    
    var trip: MTATrip
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(getRouteColor(of: trip) ?? .clear)
            
            Text(trip.getRouteId()?.rawValue ?? "")
                .font(.title3)
                .foregroundColor(getRouteIdColor(of: trip))
        }
    }
    
    
    private func getRouteColor(of trip: MTATrip) -> Color? {
        if let routeId = trip.getRouteId(), let mtaRoute = ViewModel.mtaRoutes.first(where: { $0.id == routeId }) {
            return Color(uiColor: hexStringToUIColor(mtaRoute.color))
        }
        return nil
    }
    
    private func getRouteIdColor(of trip: MTATrip) -> Color {
        switch trip.getRouteId() {
        case .n, .q, .r, .w:
            return .black
        default:
            return .white
        }
    }
    
    private func hexStringToUIColor(_ hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}


