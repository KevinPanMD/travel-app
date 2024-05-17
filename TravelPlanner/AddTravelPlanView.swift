import Foundation
import SwiftUI
import GooglePlaces

struct AddTravelPlanView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showingGooglePlacesPicker = false
    @State private var isLoading = false
    let onAdd: (String, Date, Date) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Destination", text: $destination)
                        .onTapGesture {
                            showingGooglePlacesPicker = true
                        }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Travel Plan")
            .navigationBarItems(leading: cancelButton, trailing: saveButton)
            .sheet(isPresented: $showingGooglePlacesPicker) {
                GooglePlacesPicker { selectedPlace in
                    destination = selectedPlace.name ?? ""
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Creating Itinerary...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .onDisappear {
                            isLoading = false
                        }
                }
                
            }
        }
        .navigationBarBackButtonHidden(isLoading)
    }
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    private var saveButton: some View {
        Button("Save") {
            isLoading = true
            DispatchQueue.global().async {
                onAdd(destination, startDate, endDate)
                DispatchQueue.main.async {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
struct GooglePlacesPicker: UIViewControllerRepresentable {
    let onPlaceSelected: (GMSPlace) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> GMSAutocompleteViewController {
        let viewController = GMSAutocompleteViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: Context) {
        // No updates needed
    }
    
    class Coordinator: NSObject, GMSAutocompleteViewControllerDelegate {
        let parent: GooglePlacesPicker
        
        init(_ parent: GooglePlacesPicker) {
            self.parent = parent
        }
        
        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            parent.onPlaceSelected(place)
            viewController.dismiss(animated: true, completion: nil)
        }
        
        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            print("Error: \(error.localizedDescription)")
        }
        
        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
}

struct AddTravelPlanView_Previews: PreviewProvider {
    static var previews: some View {
        AddTravelPlanView { _, _, _ in }
    }
}
