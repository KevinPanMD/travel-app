# TripAdvisor Scraper and Travel Planner

## Overview

This Swift-based application scrapes TripAdvisor for top-rated hotels, restaurants, and attractions in a given destination and generates an optimized travel itinerary. By utilizing concurrent programming, it ensures efficient data retrieval and processing to help travelers plan their trips effortlessly. The Google Maps API key had to be hidden and certain Google Maps dependencies had to be deleted for confidentiality.

## Features

- **Scrape TripAdvisor Data**: Retrieve detailed information about hotels, restaurants, and attractions, including names, ratings, reviews, and addresses.
- **Multi-Threaded Processing**: Leverage Swift's concurrency capabilities to handle multiple data retrieval tasks simultaneously.
- **Travel Mode Optimization**: Calculate the best travel mode (driving, walking, biking, transit) and distance between points using Google Maps API.
- **Itinerary Planning**: Automatically create a day-by-day itinerary, optimizing the travel route between different points of interest.

## Technologies Used

- **Swift**
- **SwiftSoup**: For HTML parsing and data extraction.
- **GoogleMaps**: To determine travel modes and distances.
- **Concurrency**: Implemented using semaphores, DispatchGroup, and thread-safe collections.

## Key Components
- **scrapTripAdvisor Class**: Handles the web scraping process, sending requests to TripAdvisor's GraphQL endpoint and parsing the responses to extract relevant data about locations, restaurants, and hotels.
- **WeightedGraph Struct**: Implements a weighted graph data structure to represent the relationships between different points of interest. It uses this structure to calculate distances and find optimal paths between attractions, hotels, and restaurants.
- **scheduler Class**: Plans itineraries for multiple days, taking into account user-defined preferences and constraints. It utilizes the weighted graph to determine the best sequence of visits and dining options.

### Prerequisites

- Xcode 12.5 or later
- Swift 5.3 or later
- CocoaPods (if managing dependencies)
