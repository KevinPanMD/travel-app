import Foundation

class ItineraryViewModel: ObservableObject {
    
    @Published var itinerary: [Int: [itin]]?
    @Published var isLoading = false
    func generateItinerary(for city: String, days: Int) -> ([Int: [itin]]){
        isLoading = true
        
        let scraper = scrapTripAdvisor()
        // Step 1: Scrape trip advisor for points of interest
        let points = scraper.getPointsOfInterest(destination: city)
        var hotels:[Point] = []
        var attractions:[Point] = []
        var restaurants:[Point] = []
        
        if let hotels2 = points[.hotel] {
            for hotel in hotels2 {
                hotels.append(hotel)
            }
        }
        if let attractions2 = points[.attraction] {
            for attraction in attractions2 {
                attractions.append(attraction)
            }
        }
        if let restaurants2 = points[.restaurant] {
            for restaurant in restaurants2 {
                restaurants.append(restaurant)
            }
        }
        
        // Step 2: Create Graph
        let graph = graphCreator(attractions: attractions, hotels: hotels, restaurants: restaurants).createGraph()
        
        // Step 3: Generate itinerary
        let scheduler = scheduler(days: days, graph: graph)
        let itinerary = scheduler.planItinerary()
        
        return itinerary
    }
}
