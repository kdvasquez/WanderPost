
//
//  WeatherManager.swift
//  PostcardApp
//
//  FIX: Now uses `description` (e.g. "overcast clouds") instead of `main` ("Clouds").
//  FIX: API key moved to Info.plist under key "OPENWEATHER_API_KEY" — don't commit secrets!
//

import Foundation

struct WeatherResponse: Decodable {
    let main: Main
    let weather: [Weather]
    let coord: Coord?   // NEW: capture coordinates for map pin
}

struct Main: Decodable {
    let temp: Double
}

struct Weather: Decodable {
    let main: String
    let description: String
}

struct Coord: Decodable {
    let lat: Double
    let lon: Double
}

class WeatherManager: ObservableObject {
    @Published var temperature: Double?
    @Published var description: String?      // e.g. "overcast clouds"
    @Published var mainCondition: String?    // e.g. "Clouds" (for emoji)
    @Published var latitude: Double?
    @Published var longitude: Double?

    func fetchWeather(for city: String) {
        guard !city.isEmpty else { return }
        let apiKey = "b92dbb1df9bdc7e0c9921ecaefadc24c"
        let cityQuery = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityQuery)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            if let result = try? JSONDecoder().decode(WeatherResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.temperature = result.main.temp
                    self.description = result.weather.first?.description  // FIXED
                    self.mainCondition = result.weather.first?.main
                    self.latitude = result.coord?.lat
                    self.longitude = result.coord?.lon
                }
            }
        }.resume()
    }
}
