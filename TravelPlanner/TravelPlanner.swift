import Foundation
import SwiftSoup
import GoogleMaps

enum PointType: Codable {
    case attraction
    case hotel
    case restaurant
    static var allCases: [PointType] {
        return [.hotel, .attraction, .restaurant]
    }
}
struct Point: Hashable, Codable {
    let name: String
    let rating: Double
    let numReview: Int
    let address: String
    let type: PointType
}

class scrapTripAdvisor
{
    final let baseHeader = [
        "authority": "www.tripadvisor.com",
        "accept-language": "en-US,en;q=0.9",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/112.0",
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
        "accept-encoding": "gzip, deflate, br",
    ]
    func search_location(query: String, session: URLSession, completion: @escaping ([String: Any]?, Error?) -> Void) {
        let url = URL(string: "https://www.tripadvisor.com/data/graphql/ids")
        var request = URLRequest(url: url!)
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var hexString = ""
        for _ in 0..<64 {
            let digit = Int.random(in: 0..<16)
            hexString += String(format: "%X", digit)
        }
        let cookie = String((0..<16).map{ _ in letters.randomElement()! })
        request.httpMethod = "POST"
        request.addValue(cookie, forHTTPHeaderField: "Cookie")
        request.addValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/112.0",forHTTPHeaderField: "User-Agent")
        request.addValue("https://www.tripadvisor.com", forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(hexString, forHTTPHeaderField: "X-Requested-By")
        request.addValue("https://www.tripadvisor.com", forHTTPHeaderField: "Origin")
        let payload = [
            [
                "query": "c9d791589f937ec371723f236edc7c6b",
                "variables": [
                    "request": [
                        "query": query,
                        "limit": 10,
                        "scope": "WORLDWIDE",
                        "locale": "en-US",
                        "searchCenter": nil,
                        "types": [
                            "LOCATION"
                        ],
                        "locationTypes": [
                            "GEO",
                            "AIRPORT",
                            "ACCOMMODATION",
                            "ATTRACTION",
                            "ATTRACTION_PRODUCT",
                            "EATERY",
                            "NEIGHBORHOOD",
                            "AIRLINE",
                            "SHOPPING",
                            "UNIVERSITY",
                            "GENERAL_HOSPITAL",
                            "PORT",
                            "FERRY",
                            "CORPORATION",
                            "VACATION_RENTAL",
                            "SHIP",
                            "CRUISE_LINE",
                            "CAR_RENTAL_OFFICE"
                        ],
                        "userId": nil,
                        "articleCategories": [
                            "default",
                            "love_your_local",
                            "insurance_lander"
                        ],
                        "enabledFeatures": [
                            "typeahead-q"
                        ]
                    ]
                ]
            ]
        ]
        let jsonPayload = try! JSONSerialization.data(withJSONObject: payload)
        request.httpBody = jsonPayload
        request.addValue(String(jsonPayload.count), forHTTPHeaderField: "Conetent-Length")
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "Unknown error")
                completion(nil, error)
                return
            }
            var found: [String: Any]? = nil
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]]
                if let jsonObject = jsonArray?.first,
                   let data = jsonObject["data"] as? [String:Any],
                   let typeaheadAutocomplete = data["Typeahead_autocomplete"] as? [String:Any],
                   let results = typeaheadAutocomplete["results"] as? [[String:Any]] {
                    let locationResults = results.filter { $0["__typename"] as? String == "Typeahead_LocationItem" }
                    if let locationResult = locationResults.first {
                        found = locationResult
                    }
                }
                completion(found, nil)
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
        task.resume()
    }
    func getBestRestaurants(destination: String, completion: @escaping ([Point]?, Error?) -> Void) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = baseHeader
        let session = URLSession(configuration: configuration)
        var searchLocationResult: [String: Any]?
        search_location(query: destination, session: session) { (response, error) in
            if let error = error {
                print("Error searching for location: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let jsonResponse = response else {
                print("Invalid response received from server")
                let error = NSError(domain: "Invalid response received from server", code: 0, userInfo: nil)
                completion(nil, error)
                return
            }
            
            searchLocationResult = jsonResponse
            
            let details = searchLocationResult!["details"] as! [String: Any]
            let restaurantsURL = details["RESTAURANTS_URL"] as? String ?? ""
            let url = URL(string: "https://www.tripadvisor.com" + restaurantsURL)!
            
            var result = [Point]()
            var links = [URL]()
            do {
                let html = try String(contentsOf: url, encoding: .utf8)
                let doc = try SwiftSoup.parse(html)
                let restaurants = try doc.select("div[data-test*='list_item']")
                for restaurant in restaurants {
                    if let firstHref = try? restaurant.select("a").first(), let href = try? firstHref.attr("href") {
                        links.append(URL(string:"https://www.tripadvisor.com"+href)!)
                    }
                }
                let group = DispatchGroup()
                let queue = DispatchQueue(label: "restaurants", attributes: .concurrent)
                for url in links {
                    group.enter()
                    queue.async {
                        guard let html = try? String(contentsOf: url) else {
                            print("Error downloading HTML from \(url)")
                            group.leave()
                            return
                        }
                        do {
                            let doc = try SwiftSoup.parse(html)
                            let address = try doc.select("span[class=yEWoV]").first()?.text() ?? ""
                            guard address != "Read more" && address != "See all" else
                            {
                                group.leave()
                                return
                            }
                            let name = try doc.select("h1.HjBfq[data-test-target=top-info-header]").first()?.text() ?? ""
                            let ratingString = try doc.select(".ZDEqb").first()?.text() ?? ""
                            let rating = Double(ratingString.filter("01234567890.".contains)) ?? 0.0
                            let numReviewText = try doc.select(".IcelI").first()?.text() ?? ""
                            let numReview = Int(numReviewText.replacingOccurrences(of: "[^\\d]+", with: "", options: .regularExpression)) ?? 0
                            result.append(Point(name: name, rating: rating, numReview: numReview, address: address, type: .restaurant))
                            group.leave()
                        } catch {
                            print("Error parsing HTML from \(url): \(error)")
                            group.leave()
                            return
                        }
                    }
                }
                group.wait()
                completion(result, nil)
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    func getBestHotels(destination: String, completion: @escaping ([Point]?, Error?) -> Void) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = baseHeader
        let session = URLSession(configuration: configuration)
        var searchLocationResult: [String: Any]?
        search_location(query: destination, session: session) { (response, error) in
            if let error = error {
                print("Error searching for location: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let jsonResponse = response else {
                print("Invalid response received from server")
                let error = NSError(domain: "Invalid response received from server", code: 0, userInfo: nil)
                completion(nil, error)
                return
            }
            
            searchLocationResult = jsonResponse
            
            let details = searchLocationResult!["details"] as! [String: Any]
            let hotelsURL = details["HOTELS_URL"] as? String ?? ""
            let url = URL(string: "https://www.tripadvisor.com" + hotelsURL)!
            
            var result = [Point]()
            var links = [URL]()
            do {
                let html = try String(contentsOf: url, encoding: .utf8)
                let doc = try SwiftSoup.parse(html)
                let hotelNames = try doc.select("a[data-clicksource=HotelName]")
                let min = min(hotelNames.count, 3)
                for Hotel in 0..<min {
                    let hotel = hotelNames[Hotel]
                    if let firstHref = try? hotel.select("a").first(), let href = try? firstHref.attr("href") {
                        links.append(URL(string:"https://www.tripadvisor.com"+href)!)
                    }
                }
                let group = DispatchGroup()
                let queue = DispatchQueue(label: "hotels", attributes: .concurrent)
                for url in links {
                    group.enter()
                    queue.async {
                        guard let html = try? String(contentsOf: url) else {
                            print("Error downloading HTML from \(url)")
                            group.leave()
                            return
                        }
                        do {
                            let doc = try SwiftSoup.parse(html)
                            let address = try doc.select("span.fHvkI.PTrfg").first()?.text() ?? ""
                            guard address != "Read more" && address != "See all" else
                            {
                                group.leave()
                                return
                            }
                            let name = try doc.select("h1#HEADING").first()?.text() ?? ""
                            let ratingString = try doc.select("span.uwJeR.P").first()?.text() ?? ""
                            let rating = Double(ratingString.filter("01234567890.".contains)) ?? 0.0
                            let numReviewText = try doc.select("span.hkxYU.q.Wi.z.Wc").first()?.text() ?? ""
                            let numReview = Int(numReviewText.replacingOccurrences(of: "[^\\d]+", with: "", options: .regularExpression)) ?? 0
                            result.append(Point(name: name, rating: rating, numReview: numReview, address: address, type: .hotel))
                            group.leave()
                        } catch {
                            print("Error parsing HTML from \(url): \(error)")
                            group.leave()
                            return
                        }
                    }
                }
                group.wait()
                completion(result, nil)
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    func getBestAttractions(destination: String, completion: @escaping ([Point]?, Error?) -> Void) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = baseHeader
        let session = URLSession(configuration: configuration)
        var searchLocationResult: [String: Any]?
        search_location(query: destination, session: session) { (response, error) in
            if let error = error {
                print("Error searching for location: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let jsonResponse = response else {
                print("Invalid response received from server")
                let error = NSError(domain: "Invalid response received from server", code: 0, userInfo: nil)
                completion(nil, error)
                return
            }
            
            searchLocationResult = jsonResponse
            
            let details = searchLocationResult!["details"] as! [String: Any]
            let temp = details["ATTRACTIONS_URL"] as? String ?? ""
            let attractionURL = "https://www.tripadvisor.com" + temp.replacingOccurrences(of: "Activities", with: "Activities-oa0-")
            
            let url = URL(string: attractionURL)!
            
            var result = [Point]()
            var links = [URL]()
            do {
                let html = try String(contentsOf: url, encoding: .utf8)
                let doc = try SwiftSoup.parse(html)
                let attractions = try doc.select(".hZuqH")
                for attraction in attractions {
                    if let firstHref = try? attraction.select("a").first(), let href = try? firstHref.attr("href") {
                        links.append(URL(string:"https://www.tripadvisor.com"+href)!)
                    }
                }
                let group = DispatchGroup()
                let queue = DispatchQueue(label: "restaurants", attributes: .concurrent)
                for url in links {
                    group.enter()
                    queue.async {
                        guard let html = try? String(contentsOf: url) else {
                            print("Error downloading HTML from \(url)")
                            group.leave()
                            return
                        }
                        do {
                            let doc = try SwiftSoup.parse(html)
                            let element = try doc.select("span.biGQs._P.XWJSj.Wb")
                            let address = try element[9].text()
                            guard address != "Read more" && address != "See all" else
                            {
                                group.leave()
                                return
                            }
                            let name = try doc.select("h1.biGQs._P.fiohW.eIegw[data-automation=mainH1]").first()?.text() ?? ""
                            let ratingString = try doc.select("div.biGQs._P.fiohW.hzzSG.uuBRH").first()?.text() ?? ""
                            let rating = Double(ratingString.filter("01234567890.".contains)) ?? 0.0
                            let numReviewText = try doc.select(".KAVFZ").first()?.text() ?? ""
                            let numReview = Int(numReviewText.replacingOccurrences(of: "[^\\d]+", with: "", options: .regularExpression)) ?? 0
                            result.append(Point(name: name, rating: rating, numReview: numReview, address: address, type: .attraction))
                            group.leave()
                        } catch {
                            print("Error parsing HTML from \(url): \(error)")
                            group.leave()
                            return
                        }
                    }
                }
                group.wait()
                completion(result, nil)
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    func getPointsOfInterest(destination: String) -> [PointType: [Point]]{
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "places", attributes: .concurrent)
        var result: [PointType: [Point]] = [:]
        let lock = NSLock()
        group.enter()
        queue.async {
            self.getBestAttractions(destination: destination) { points, err in
                defer { group.leave() }
                guard err == nil else {return }
                guard let points = points else {return}
                lock.lock()
                result[.attraction] = points
                lock.unlock()
            }
        }
        group.enter()
        queue.async {
            self.getBestHotels(destination: destination) { points, err in
                defer { group.leave() }
                guard err == nil else {return }
                guard let points = points else { return }
                lock.lock()
                result[.hotel] = points
                lock.unlock()
            }
        }
        group.enter()
        queue.async {
            self.getBestRestaurants(destination: destination) { points, err in
                defer { group.leave() }
                guard err == nil else {return }
                guard let points = points else { return }
                lock.lock()
                result[.restaurant] = points
                lock.unlock()
            }
        }
        group.wait()
        return result
    }
}
enum TravelMode: String, Codable {
    case driving
    case walking
    case biking
    case transit
    case fail
}
func getBestTravelMode(source: String, destination: String) -> (mode: TravelMode, distance: Double)? {
    
    let apiKey = "AIzaSyCF98BYubglPgDYQoGZn9rgTut5aaETKsA"
    let baseURL = "https://maps.googleapis.com/maps/api/directions/json?"
    let modes: [TravelMode] = [.driving, .walking, .biking, .transit]
    
    var fastestMode: TravelMode = .fail
    var fastestDistance: Double = Double.greatestFiniteMagnitude
    
    for mode in modes {
        if let encodedSource = source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "\(baseURL)origin=\(encodedSource)&destination=\(encodedDestination)&mode=\(mode.rawValue)&key=\(apiKey)"){
            if let data = try? Data(contentsOf: url), let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let routes = json["routes"] as? [[String: Any]], let route = routes.first, let legs = route["legs"] as? [[String: Any]], let leg = legs.first, let distance = leg["duration"] as? [String: Any], let value = distance["value"] as? Double {
                
                if value < fastestDistance {
                    fastestDistance = value
                    fastestMode = mode
                }
            }
        }
    }
    if fastestMode != .fail
    {
        return (fastestMode, fastestDistance)
    }
    else
    {
        return nil
    }
}
struct Edge {
    let destination: Point
    let weight: (TravelMode, Double)?
}

struct WeightedGraph {
    var adjacencyList: [Point: [Edge]] = [:]
    
    mutating func addEdge(from source: Point, to destination: Point, weight: (TravelMode, Double)?) {
        let edge = Edge(destination: destination, weight: weight)
        if adjacencyList[source] == nil {
            adjacencyList[source] = [edge]
        } else {
            adjacencyList[source]?.append(edge)
        }
    }
    
    func getEdges(for Point: Point) -> [Edge] {
        return adjacencyList[Point] ?? []
    }
    func closestPoint(from:Point, type:PointType) -> itin?
    {
        var min:Double = Double.greatestFiniteMagnitude
        var locate:Point? = nil
        var mode:(TravelMode,Double)? = nil
        let list = adjacencyList[from] ?? []
        for e in list
        {
            let curr = e.destination
            if curr.type == type
            {
                if e.weight?.1 ?? Double.greatestFiniteMagnitude < min
                {
                    locate = curr
                    mode = e.weight
                    min = e.weight!.1
                }
            }
        }
        if locate == nil
        {
            return nil
        }
        return itin(point: locate!, travelMode: mode!.0, duration: mode!.1)
    }
    mutating func deletePoint(target:Point)
    {
        let list = adjacencyList[target] ?? []
        for e in list
        {
            adjacencyList[e.destination]?.removeAll(where: {$0.destination == target})
        }
        adjacencyList[target] = nil
    }
    func getDistance(Point1: Point, Point2: Point) -> (mode: TravelMode, distance: Double)? {
        return getBestTravelMode(source: Point1.address, destination: Point2.address)
    }
}
class graphCreator {
    var attractions: [Point]
    var hotels: [Point]
    var restaurants: [Point]
    init(attractions: [Point], hotels: [Point], restaurants: [Point]) {
        self.attractions = attractions
        self.hotels = hotels
        self.restaurants = restaurants
    }
    
    func getDistance(Point1: Point, Point2: Point) -> (mode: TravelMode, distance: Double)? {
        return getBestTravelMode(source: Point1.address, destination: Point2.address)
    }
    func createGraph() -> WeightedGraph {
        var graph = WeightedGraph()
        let lock = NSLock()
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "createGraphQueue", attributes: .concurrent)
        
        // Add attractions edges
        for attraction in attractions {
            dispatchGroup.enter()
            dispatchQueue.async {
                for Point in self.attractions {
                    if attraction.name != Point.name {
                        if let distance = self.getDistance(Point1: attraction, Point2: Point) {
                            lock.lock()
                            graph.addEdge(from: attraction, to: Point, weight: distance)
                            lock.unlock()
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        // Add restaurant edges
        for attraction in attractions {
            dispatchGroup.enter()
            dispatchQueue.async {
                for restaurant in self.restaurants {
                    if let distance = self.getDistance(Point1: attraction, Point2: restaurant) {
                        lock.lock()
                        graph.addEdge(from: attraction, to: restaurant, weight: distance)
                        graph.addEdge(from: restaurant, to: attraction, weight: distance)
                        lock.unlock()
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        // Add hotel edges
        for attraction in attractions {
            dispatchGroup.enter()
            dispatchQueue.async {
                for hotel in self.hotels {
                    if let distance = self.getDistance(Point1: attraction, Point2: hotel) {
                        lock.lock()
                        graph.addEdge(from: attraction, to: hotel, weight: distance)
                        graph.addEdge(from: hotel, to: attraction, weight: distance)
                        lock.unlock()
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        // Wait for all async tasks to complete
        dispatchGroup.wait()
        
        return graph
    }
}
class scheduler {
    let days: Int
    var graph: WeightedGraph
    
    init(days: Int, graph: WeightedGraph) {
        self.days = days
        self.graph = graph
    }
    func planItinerary() -> [Int: [itin]] {
        var itinerary: [Int: [itin]] = [:]
        var hotels: [Point] = []
        var attractions: [Point] = []
        var restaurants: [Point] = []
        for Point in graph.adjacencyList.keys {
            switch Point.type {
            case .hotel:
                hotels.append(Point)
            case .attraction:
                attractions.append(Point)
            case .restaurant:
                restaurants.append(Point)
            }
        }
        guard let chosenHotel = hotels.max(by: {$0.rating < $1.rating}) else {
            for day in 1...days
            {
                itinerary[day] = []
            }
            return itinerary
        }
        var last:Point = chosenHotel
        var path:[itin] = [itin(point: chosenHotel, travelMode: .fail, duration: 0)]
        var status = 0
        for day in 1...days {
            while status < 5 {
                if let chosenAttraction = graph.closestPoint(from: last, type: .attraction) {
                    if(last.type == .restaurant)
                    {
                        path.append(chosenAttraction)
                        graph.deletePoint(target: last)
                    }
                    else
                    {
                        path.append(chosenAttraction)
                    }
                    last = chosenAttraction.point
                }
                status += 1
                if(status < 5)
                {
                    if let chosenRestaurant = graph.closestPoint(from: last, type: .restaurant) {
                        path.append(chosenRestaurant)
                        graph.deletePoint(target: last)
                        last = chosenRestaurant.point
                    }
                    status+=1
                }
            }
            if let add = graph.getDistance(Point1: chosenHotel, Point2: last)
            {
                path.append(itin(point: chosenHotel, travelMode: add.mode, duration: add.distance))
            }
            else
            {
                path.append(itin(point: chosenHotel, travelMode: .fail, duration: 0))
            }
            itinerary[day] = path
            path = [itin(point: chosenHotel, travelMode: .fail, duration: 0)]
            status = 0
            last = chosenHotel
        }
        
        return itinerary
    }
}

