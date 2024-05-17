//
//  TravelPlannerApp.swift
//  TravelPlanner
//
//  Created by Dingwen Wang on 2023/4/14.
//

import SwiftUI
import GooglePlaces

@main
struct TravelPlannerApp: App {
    init() {
        GMSPlacesClient.provideAPIKey("AIzaSyCF98BYubglPgDYQoGZn9rgTut5aaETKsA")
    }

    var body: some Scene {
        WindowGroup {
            TravelPlanListView()
        }
    }
}
