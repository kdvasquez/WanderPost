
//
//  FirebaseManager.swift
//  PostcardApp
//

import Foundation
import FirebaseStorage
import FirebaseFirestore
import UIKit

class FirebaseManager {
    static let shared = FirebaseManager()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private init() {}

    func uploadPostcard(
        image: UIImage,
        city: String,
        message: String,
        weather: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(AppError.imageConversionFailed))
            return
        }

        let id = UUID().uuidString
        let storageRef = storage.reference().child("postcards/\(id).jpg")

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error { completion(.failure(error)); return }

            storageRef.downloadURL { url, error in
                if let error = error { completion(.failure(error)); return }
                guard let downloadURL = url else {
                    completion(.failure(AppError.missingDownloadURL)); return
                }

                let data: [String: Any] = [
                    "city": city,
                    "message": message,
                    "weather": weather,
                    "imageURL": downloadURL.absoluteString,
                    "timestamp": Timestamp(date: Date())
                ]

                self.db.collection("postcards").document(id).setData(data) { error in
                    if let error = error { completion(.failure(error)) }
                    else { completion(.success(())) }
                }
            }
        }
    }
}

enum AppError: LocalizedError {
    case imageConversionFailed
    case missingDownloadURL

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Could not convert image for upload."
        case .missingDownloadURL: return "Failed to retrieve image URL after upload."
        }
    }
}
