import XCTest
@testable import TravelPlanner

final class TravelPlannerTests: XCTestCase {
    var session: URLSession!
        var scrap: scrapTripAdvisor!
        
        override func setUpWithError() throws {
            try super.setUpWithError()
            session = URLSession(configuration: .default)
            scrap = scrapTripAdvisor()
        }
        
        override func tearDownWithError() throws {
            session = nil
            scrap = nil
            try super.tearDownWithError()
        }
        
    func testSearchLocation() {
    let scrap = scrapTripAdvisor()
    let expectation = self.expectation(description: "Search location")
    let query = "paris"
    let session = URLSession(configuration: URLSessionConfiguration.default)
        scrap.search_location(query: query, session: session) { (response, error) in
        XCTAssertNil(error)
        XCTAssertNotNil(response)
        expectation.fulfill()
    }
    waitForExpectations(timeout: 10, handler: nil)
    }
    func testGetBestRestaurants() {
        let expectation = self.expectation(description: "Get best restaurants")
        let scrapTripAdvisor = scrapTripAdvisor()
        
        let destination = "Washington D.C"
        scrapTripAdvisor.getBestRestaurants(destination: destination) { (points, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(points)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
        
    func testGetBestHotels() {
        let expectation = self.expectation(description: "Get best restaurants")
        let scrapTripAdvisor = scrapTripAdvisor()
        
        let destination = "Washington D.C"
        scrapTripAdvisor.getBestHotels(destination: destination) { (points, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(points)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
        
    func testGetBestAttractions() {
        let expectation = self.expectation(description: "Get best restaurants")
        let scrapTripAdvisor = scrapTripAdvisor()
        
        let destination = "Washington D.C"
        scrapTripAdvisor.getBestAttractions(destination: destination) { (points, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(points)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    func testGraphCreation() {
        let location1 = Location(name: "Eiffel Tower", rating: 4.5, numReview: 20000, latitude: 48.8582, longitude: 2.2945, type: .attraction)
        let location2 = Location(name: "The Louvre", rating: 4.6, numReview: 38000, latitude: 48.8606, longitude: 2.3376, type: .attraction)
        let location3 = Location(name: "Hotel Lutetia", rating: 4.8, numReview: 1000, latitude: 48.8514, longitude: 2.3233, type: .hotel)
        let location4 = Location(name: "Le Jules Verne", rating: 4.7, numReview: 1500, latitude: 48.8584, longitude: 2.2945, type: .restaurant)
        let graphCreator = graphCreator(attractions: [location1, location2], hotels: [location3], restaurants: [location4])
        let graph = graphCreator.createGraph()
        XCTAssertEqual(graph.adjacencyList[location1]?.count, 3)
        XCTAssertEqual(graph.adjacencyList[location2]?.count, 3)
    }
}
