//
//  SchedulerTests.swift
//  TravelPlannerTests
//
//  Created by kellclaw on 5/1/23.
//

import XCTest
@testable import TravelPlanner
final class SchedulerTests: XCTestCase {
    var graph: WeightedGraph!
    var scheduler: scheduler!
    
    override func setUp() {
        super.setUp()
        graph = WeightedGraph()
        let locations: [Location] = [
            Location(name: "Hotel A", type: .hotel, rating: 4.0),
            Location(name: "Hotel B", type: .hotel, rating: 3.5),
            Location(name: "Restaurant A", type: .restaurant, rating: 4.5),
            Location(name: "Restaurant B", type: .restaurant, rating: 3.0),
            Location(name: "Attraction A", type: .attraction, rating: 4.0),
            Location(name: "Attraction B", type: .attraction, rating: 3.5),
            Location(name: "Attraction C", type: .attraction, rating: 4.5)
        ]
        for location in locations {
            graph.addLocation(location)
        }
        graph.addUndirectedEdge(from: locations[0], to: locations[2], weight: 2.0)
        graph.addUndirectedEdge(from: locations[0], to: locations[4], weight: 3.0)
        graph.addUndirectedEdge(from: locations[1], to: locations[3], weight: 1.0)
        graph.addUndirectedEdge(from: locations[1], to: locations[5], weight: 2.0)
        graph.addUndirectedEdge(from: locations[2], to: locations[4], weight: 1.0)
        graph.addUndirectedEdge(from: locations[2], to: locations[6], weight: 3.0)
        graph.addUndirectedEdge(from: locations[3], to: locations[5], weight: 2.0)
        scheduler = scheduler(days: 2, graph: graph)
    }
    
    func testPlanItinerary() {
        let itinerary = scheduler.planItinerary()
        XCTAssertEqual(itinerary.count, 2, "Itinerary should have 2 days")
        XCTAssertEqual(itinerary["Day 1"]?.count, 7, "Day 1 itinerary should have 7 locations")
        XCTAssertEqual(itinerary["Day 2"]?.count, 7, "Day 2 itinerary should have 7 locations")
        XCTAssertTrue(itinerary["Day 1"]!.first!.type == .hotel, "First location of Day 1 should be a hotel")
        XCTAssertTrue(itinerary["Day 2"]!.first!.type == .hotel, "First location of Day 2 should be a hotel")
        XCTAssertTrue(itinerary["Day 1"]!.last!.type == .hotel, "Last location of Day 1 should be a hotel")
        XCTAssertTrue(itinerary["Day 2"]!.last!.type == .hotel, "Last location of Day 2 should be a hotel")
    }
    
}
