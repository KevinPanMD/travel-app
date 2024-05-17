import Foundation
import SwiftUI
import GoogleMaps

struct Activity: Identifiable, Codable, Hashable {
    var id = UUID()
    let place: String
    let duration: TimeInterval
    let transportation: Transportation
}

enum Transportation: String, CaseIterable, Identifiable, Codable {
    case walking
    case cycling
    case driving
    case publicTransit = "public transit"

    var id: String { self.rawValue }
}

struct TravelPlanEditorView: View {
    @Binding var planId: UUID
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var schedule: [Int:[itin]]
    @State private var days: [[Activity]] = [[]]
    @State private var selectedDay = 0
    @State private var showingAddActivityView = false
    @State private var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    private var dateText: [String] = []
    

    private var numberOfDays: Int {
        let calendar = Calendar.current
        let startOfDay1 = calendar.startOfDay(for: startDate)
        let startOfDay2 = calendar.startOfDay(for: endDate)
        let daysBetween = calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2).day ?? 0
        return daysBetween + 1
    }
    private func trans(mode : TravelMode) -> Transportation
    {
        switch mode {
        case .driving:
            return Transportation.driving
        case .walking:
            return Transportation.walking
        case .biking:
            return Transportation.cycling
        case .transit:
            return Transportation.publicTransit
        case .fail:
            return Transportation.walking
        }
    }
    init(planId: Binding<UUID>, startDate: Binding<Date>, endDate: Binding<Date>, schedule: [Int:[itin]]) {
        self._planId = planId
        self._startDate = startDate
        self._endDate = endDate
        self._schedule = State(initialValue:schedule)
        print("Init \(planId)")
        var itin:[[Activity]] = []
        for index in 1...numberOfDays {
            itin.append([])
            let itinerary = schedule[index]!
            for e in itinerary
            {
                let curr = Activity(place: e.point.name, duration: e.duration, transportation: trans(mode:e.travelMode))
                itin[index-1].append(curr)
            }
        }
        self._days = State(initialValue: itin)
        loadDays()
        for index in 0..<numberOfDays {
            let date = Calendar.current.date(byAdding: .day, value: index, to: startDate.wrappedValue)!
            let dateString = formatter.string(from: date)
            dateText.append(dateString)
        }
    }
    var body: some View {
        VStack {
            Text("\(planId)")
            Picker("Day", selection: $selectedDay) {
                ForEach(0..<numberOfDays) { index in
                    Text(dateText[index])
                }
            }
            .pickerStyle(NavigationLinkPickerStyle())
            .padding()
            let days2 = self.days
            List {
                ForEach(days2[selectedDay], id: \.self) { activity in
                    VStack(alignment: .leading) {
                        Text(activity.place)
                            .font(.headline)
                        HStack {
                            Text("Duration: \(timeFormatter.string(from: activity.duration) ?? "Unknown duration")")

                            Text("Transportation: \(activity.transportation.rawValue.capitalized)")
                        }
                    }
                }
                .onDelete(perform: deleteActivity)
                .onMove(perform: moveActivity)
            }

            Button("Add Activity") {
                showingAddActivityView = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .sheet(isPresented: $showingAddActivityView) {
                AddActivityView { place, duration, transportation in
                    let newActivity = Activity(place: place, duration: duration, transportation: transportation)
                    days[selectedDay].append(newActivity)
                    saveDays()
                    showingAddActivityView = false
                }
            }
        }
        .navigationTitle("Travel Plan Editor")
        .onAppear {
            loadDays()
        }
        .onDisappear {
            saveDays()
        }
    }

    private func deleteActivity(at offsets: IndexSet) {
        withAnimation {
            days[selectedDay].remove(atOffsets: offsets)
            saveDays()
        }
    }
    
    private func moveActivity(from source: IndexSet, to destination: Int) {
        withAnimation {
            days[selectedDay].move(fromOffsets: source, toOffset: destination)
            saveDays()
        }
    }
    
    private func saveDays() {
        do {
            let data = try PropertyListEncoder().encode(days)
            UserDefaults.standard.set(data, forKey: "\(planId.uuidString)")
            print("Data saved successfully")
        } catch {
            print("Failed to save data: \(error)")
        }
    }

    
    private func loadDays() {
        print("Load Days")
        if let data = UserDefaults.standard.value(forKey: "\(planId.uuidString)") as? Data {
            if let savedDays = try? PropertyListDecoder().decode([[Activity]].self, from: data) {
                days = savedDays
                print("Load Success")
            }
        } else {
            if days.count != numberOfDays {
                days = Array(repeating: [], count: numberOfDays)
            }
            saveDays()
        }
    }
}

private let timeFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return formatter
}()

struct TravelPlanEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TravelPlanEditorView(
            planId: .constant(UUID()),
            startDate: .constant(Date()),
            endDate: .constant(Calendar.current.date(byAdding: .day, value: 5, to: Date())!),
            schedule: [:])
    }
}
