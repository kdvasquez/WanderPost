//
//  EditorPage.swift
//  PostcardApp — WanderPost
//

import SwiftUI
import MapKit
import Combine

struct EditorPage: View {
    @EnvironmentObject var viewModel: PostcardViewModel
    @EnvironmentObject var locationManager: CoreLocationManager
    @EnvironmentObject var weatherManager: WeatherManager
    @Environment(\.navPath) var navPath

    @State private var cityName: String
    @State private var message: String

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    )

    @State private var cityDebounce = PassthroughSubject<String, Never>()
    @State private var cancellables = Set<AnyCancellable>()

    var existingPostcard: Postcard?

    init(postcard: Postcard? = nil) {
        _cityName = State(initialValue: postcard?.cityName ?? "")
        _message = State(initialValue: postcard?.message ?? "")
        self.existingPostcard = postcard
    }

    private var resolvedLat: Double? { weatherManager.latitude }
    private var resolvedLon: Double? { weatherManager.longitude }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("ParchmentBG"), Color("ParchmentBG").opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Photo
                    if let image = existingPostcard != nil
                        ? UIImage(data: existingPostcard!.imageData)
                        : viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color("InkBrown").opacity(0.25), radius: 12, y: 6)
                            .padding(.horizontal, 20)
                    }

                    // City Field
                    WanderField(label: "City", placeholder: "e.g. Tokyo", text: $cityName)
                        .onChange(of: cityName) { newCity in cityDebounce.send(newCity) }
                        .padding(.horizontal, 20)

                    // Location autofill
                    if cityName.isEmpty && !locationManager.cityName.isEmpty {
                        Button {
                            cityName = locationManager.cityName
                            cityDebounce.send(cityName)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill").font(.system(size: 12))
                                Text("Use My Location: \(locationManager.cityName)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(Color("AccentTan"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color("AccentTan").opacity(0.12)))
                        }
                    }

                    // Weather badge
                    if let temp = weatherManager.temperature,
                       let desc = weatherManager.description {
                        HStack(spacing: 8) {
                            Text(weatherIcon(for: weatherManager.mainCondition ?? ""))
                            Text("\(desc.capitalized) · \(Int(temp))°C")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color("InkBrown").opacity(0.75))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .shadow(color: Color("InkBrown").opacity(0.08), radius: 6, y: 2)
                        )
                    } else if !cityName.isEmpty {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7).tint(Color("AccentTan"))
                            Text("Fetching weather…")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(Color("InkBrown").opacity(0.4))
                        }
                    }

                    // Message Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("InkBrown").opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1.5)
                            .padding(.horizontal, 20)

                        TextEditor(text: $message)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(Color("InkBrown"))
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.85))
                                    .shadow(color: Color("InkBrown").opacity(0.07), radius: 6, y: 2)
                            )
                            .padding(.horizontal, 20)
                    }

                    // Map Preview
                    Map(coordinateRegion: $region)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .shadow(color: Color("InkBrown").opacity(0.15), radius: 8, y: 4)

                    // Save Button — pushes saveShare route onto nav stack
                    Button { handleSave() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Postcard")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentTan"), Color("InkBrown")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color("InkBrown").opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupDebounce()
            if !cityName.isEmpty {
                weatherManager.fetchWeather(for: cityName)
                updateMapFor(city: cityName)
            }
        }
    }

    func setupDebounce() {
        cityDebounce
            .debounce(for: .milliseconds(600), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { city in
                guard !city.isEmpty else { return }
                weatherManager.fetchWeather(for: city)
                updateMapFor(city: city)
            }
            .store(in: &cancellables)
    }

    func handleSave() {
        let weatherText = weatherManager.description ?? "N/A"
        var savedID: UUID?

        if let postcard = existingPostcard {
            viewModel.updatePostcard(postcard, newCity: cityName, newMessage: message,
                                     latitude: resolvedLat, longitude: resolvedLon)
            viewModel.updatePostcardWeather(postcard, weather: weatherText)
            savedID = viewModel.postcards.first { $0.id == postcard.id }?.id
        } else {
            viewModel.savePostcard(city: cityName, message: message,
                                   latitude: resolvedLat, longitude: resolvedLon)
            if let last = viewModel.postcards.last {
                viewModel.updatePostcardWeather(last, weather: weatherText)
                savedID = last.id
            }
        }

        // Push saveShare onto the nav stack — resetToHome() will unwind everything
        if let id = savedID {
            navPath.wrappedValue.append(.saveShare(id))
        }
    }

    func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear":        return "☀️"
        case "clouds":       return "☁️"
        case "rain":         return "🌧️"
        case "drizzle":      return "🌦️"
        case "thunderstorm": return "⛈️"
        case "snow":         return "❄️"
        case "mist", "fog":  return "🌫️"
        default:             return "🌈"
        }
    }

    func updateMapFor(city: String) {
        CLGeocoder().geocodeAddressString(city) { placemarks, _ in
            if let coord = placemarks?.first?.location?.coordinate {
                withAnimation(.easeInOut(duration: 0.5)) {
                    region = MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    )
                }
            }
        }
    }
}

// MARK: - WanderPost text field

struct WanderField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color("InkBrown").opacity(0.5))
                .textCase(.uppercase)
                .tracking(1.5)
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color("InkBrown"))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color("InkBrown").opacity(0.07), radius: 6, y: 2)
                )
        }
    }
}
