//
//  TravelPlanListView.swift
//  TravelPlanner
//
//  Created by Dingwen Wang on 2023/4/14.
//

import Foundation
import SwiftUI
struct itin: Codable
{
    let point: Point
    let travelMode: TravelMode
    let duration: Double
    init(point: Point, travelMode: TravelMode, duration: Double) {
        self.point = point
        self.travelMode = travelMode
        self.duration = duration
    }
}
struct TravelPlan: Identifiable, Codable {
    var id = UUID()
    let destination: String
    let startDate: Date
    let endDate: Date
    let schedule: [Int : [itin]]
}

struct TravelPlanListView: View {
    @State private var travelPlans: [TravelPlan] = []
    @State private var showingAddPlanView = false
    @EnvironmentObject var viewModel:ItineraryViewModel
    var body: some View {
        NavigationView {
            List {
                ForEach(travelPlans) { plan in
                    NavigationLink(destination: TravelPlanEditorView(planId: Binding.constant(plan.id), startDate: Binding.constant(plan.startDate), endDate: Binding.constant(plan.endDate), schedule: plan.schedule)) {
                        VStack(alignment: .leading) {
                            Text(plan.destination)
                                .font(.headline)
                            HStack {
                                Text("Start Date: \(plan.startDate, formatter: dateFormatter)")
                                Text("End Date: \(plan.endDate, formatter: dateFormatter)")
                            }
                        }
                    }
                }
                .onDelete(perform: deleteTravelPlan)
            }
            .navigationBarTitle("Travel Plans")
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .sheet(isPresented: $showingAddPlanView) {
                AddTravelPlanView { destination, startDate, endDate in
                    var numberOfDays: Int {
                        let calendar = Calendar.current
                        let startOfDay1 = calendar.startOfDay(for: startDate)
                        let startOfDay2 = calendar.startOfDay(for: endDate)
                        let daysBetween = calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2).day ?? 0
                        return daysBetween + 1
                    }
                    let itineraryVM = ItineraryViewModel()
                    let itinerary = itineraryVM.generateItinerary(for: destination, days: numberOfDays)
                    let newPlan = TravelPlan(destination: destination, startDate: startDate, endDate: endDate, schedule: itinerary)
                    self.travelPlans.append(newPlan)
                    saveTravelPlans()
                    self.showingAddPlanView = false
                }
            }
        }.onAppear(perform: loadTravelPlans)
    }
    
    private var addButton: some View {
        Button(action: {
            showingAddPlanView = true
        }) {
            Image(systemName: "plus")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundColor(.blue)
        }
    }
    
    private func deleteTravelPlan(at offsets: IndexSet) {
        travelPlans.remove(atOffsets: offsets)
        saveTravelPlans()
    }
    
    private func saveTravelPlans() {
        if let encoded = try? JSONEncoder().encode(travelPlans) {
            UserDefaults.standard.set(encoded, forKey: "travelPlans")
        }
    }

    private func loadTravelPlans() {
        if let data = UserDefaults.standard.data(forKey: "travelPlans") {
            if let decoded = try? JSONDecoder().decode([TravelPlan].self, from: data) {
                travelPlans = decoded
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct TravelPlanListView_Previews: PreviewProvider {
    static var previews: some View {
        TravelPlanListView()
    }
}
