
//
//  PostcardViewModel.swift
//  PostcardApp
//

import Foundation
import SwiftUI

class PostcardViewModel: ObservableObject {

    @Published var postcards: [Postcard] = [] {
        didSet { save() }
    }

    var visitedCities: [String] {
        Array(Set(postcards.map { $0.cityName })).sorted()
    }

    @Published var selectedImage: UIImage?

    // MARK: - CRUD

    func savePostcard(city: String, message: String, latitude: Double? = nil, longitude: Double? = nil) {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let newPostcard = Postcard(
            imageData: imageData,
            cityName: city,
            message: message,
            dateCreated: Date(),
            weatherDescription: nil,
            latitude: latitude,
            longitude: longitude
        )
        postcards.append(newPostcard)
        selectedImage = nil
    }

    func updatePostcard(_ postcard: Postcard, newCity: String, newMessage: String,
                        latitude: Double? = nil, longitude: Double? = nil) {
        guard let index = postcards.firstIndex(where: { $0.id == postcard.id }) else { return }
        var updated = postcard
        updated.cityName = newCity
        updated.message = newMessage
        if let lat = latitude { updated.latitude = lat }
        if let lon = longitude { updated.longitude = lon }
        postcards[index] = updated
    }

    func updatePostcardWeather(_ postcard: Postcard, weather: String) {
        guard let index = postcards.firstIndex(where: { $0.id == postcard.id }) else { return }
        postcards[index].weatherDescription = weather
    }

    func removePostcard(_ postcard: Postcard) {
        postcards.removeAll { $0.id == postcard.id }
    }

    // MARK: - Persistence

    private func save() {
        let url = getDocumentsDirectory().appendingPathComponent("postcards.json")
        if let data = try? JSONEncoder().encode(postcards) {
            try? data.write(to: url)
        }
    }

    func load() {
        let url = getDocumentsDirectory().appendingPathComponent("postcards.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Postcard].self, from: data) {
            postcards = decoded
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
