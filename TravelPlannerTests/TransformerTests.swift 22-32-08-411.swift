import XCTest
@testable import TravelPlanner

class TransformerTests: XCTestCase {
    
    var transformer =  transformer(attractions: [], hotels: [], restaurants: [])

    override func setUp() {
        super.setUp()
        transformer = transformer(
            attractions: [Point(name: "Statue of Liberty", rating: 4.5, numReview: 10000, address: "New York, NY", type: .attraction),
                          Point(name: "Golden Gate Bridge", rating: 4.7, numReview: 8000, address: "San Francisco, CA", type: .attraction)],
            hotels: [Point(name: "Hotel 1", rating: 3.8, numReview: 500, address: "New York, NY", type: .hotel),
                     Point(name: "Hotel 2", rating: 4.2, numReview: 1000, address: "San Francisco, CA", type: .hotel)],
            restaurants: [Point(name: "Restaurant 1", rating: 4.1, numReview: 2000, address: "New York, NY", type: .restaurant),
                          Point(name: "Restaurant 2", rating: 4.5, numReview: 3000, address: "San Francisco, CA",type: .restaurant)]
        )
    }
    
    func testGetCoordinateFrom() {
        let expectation = self.expectation(description: "Coordinates should be returned")
        transformer.getCoordinateFrom(address: "New York, NY") { latitude, longitude in
            XCTAssertNotNil(latitude)
            XCTAssertNotNil(longitude)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetLocationFrom() {
        let expectation = self.expectation(description: "Location should be returned")
        let point = Point(name: "Statue of Liberty", rating: 4.5, numReview: 10000, address: "New York, NY")
        transformer.getLocationFrom(Point: point) { location in
            XCTAssertNotNil(location)
            XCTAssertEqual(location?.name, point.name)
            XCTAssertEqual(location?.rating, point.rating)
            XCTAssertEqual(location?.numReview, point.numReview)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testTransformPointsToLocations() {
        let expectation = self.expectation(description: "Locations should be transformed")
        transformer.transformPointsToLocations { attractions, hotels, restaurants in
            XCTAssertEqual(attractions.count, 2)
            XCTAssertEqual(hotels.count, 2)
            XCTAssertEqual(restaurants.count, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 20.0, handler: nil)
    }
}
