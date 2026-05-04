//
//  Postcard.swift
//  PostcardApp — WanderPost
//

import Foundation
import SwiftUI

struct Postcard: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var imageData: Data
    var cityName: String
    var message: String
    var dateCreated: Date
    var weatherDescription: String?
    var latitude: Double?
    var longitude: Double?

    static func == (lhs: Postcard, rhs: Postcard) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
