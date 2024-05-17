//
//  AddActivityView.swift
//  TravelPlanner
//
//  Created by Dingwen Wang on 2023/4/14.
//

import Foundation
import SwiftUI
import GooglePlaces

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var place: String = ""
    @State private var duration: TimeInterval = 3600
    @State private var transportation: Transportation = .walking
    @State private var showingGooglePlacesPicker = false
    
    let onAdd: (String, TimeInterval, Transportation) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Place", text: $place)
                        .onTapGesture {
                            showingGooglePlacesPicker = true
                        }
                    
                    Picker("Transportation", selection: $transportation) {
                        ForEach(Transportation.allCases) { transportation in
                            Text(transportation.rawValue.capitalized).tag(transportation)
                        }
                    }
                    
                    Stepper(value: $duration, in: 600...86400, step: 600) {
                        Text("Duration: \(timeFormatter.string(from: duration) ?? "Unknown duration")")
                    }

                }
            }
            .navigationTitle("Add Activity")
            .navigationBarItems(leading: cancelButton, trailing: saveButton)
            .sheet(isPresented: $showingGooglePlacesPicker) {
                GooglePlacesPicker { selectedPlace in
                    place = selectedPlace.name ?? ""
                }
            }
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            onAdd(place, duration, transportation)
            presentationMode.wrappedValue.dismiss()
            
        }
    }
}

private let timeFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return formatter
}()

struct AddActivityView_Previews: PreviewProvider {
    static var previews: some View {
        AddActivityView { _, _, _ in }
    }
}
