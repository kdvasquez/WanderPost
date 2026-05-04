//
//  StampsPage.swift
//  PostcardApp — WanderPost
//
//  NEW: Tapping a city stamp chip flies the map to that city's pin and shows its detail card.
//

import SwiftUI
import MapKit

struct PostcardAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let postcard: Postcard
}

struct StampsPage: View {
    @EnvironmentObject var viewModel: PostcardViewModel

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 10),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    @State private var selectedAnnotation: PostcardAnnotation? = nil

    var annotations: [PostcardAnnotation] {
        viewModel.postcards.compactMap { postcard in
            guard let lat = postcard.latitude, let lon = postcard.longitude else { return nil }
            return PostcardAnnotation(
                id: postcard.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                postcard: postcard
            )
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    PinView(postcard: annotation.postcard,
                            isSelected: selectedAnnotation?.id == annotation.id)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedAnnotation = (selectedAnnotation?.id == annotation.id)
                                    ? nil : annotation
                                if let ann = annotations.first(where: { $0.id == annotation.id }) {
                                    flyTo(ann.coordinate)
                                }
                            }
                        }
                }
            }
            .ignoresSafeArea(edges: .top)

            if let selected = selectedAnnotation {
                PinDetailCard(postcard: selected.postcard) {
                    withAnimation { selectedAnnotation = nil }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            } else {
                stampShelf
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("World Map")
        .navigationBarTitleDisplayMode(.large)
    }

    // Fly map to a coordinate with a close zoom
    func flyTo(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.6)) {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
            )
        }
    }

    // Find the annotation for a given city name and fly to it
    func flyToCity(_ city: String) {
        guard let match = annotations.first(where: {
            $0.postcard.cityName.lowercased() == city.lowercased()
        }) else { return }

        withAnimation(.spring()) {
            selectedAnnotation = match
            flyTo(match.coordinate)
        }
    }

    // MARK: - Stamp shelf

    var stampShelf: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            if viewModel.visitedCities.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("🌊").font(.largeTitle)
                        Text("Create a postcard to pin cities on the map")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color("InkBrown").opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                Text("Cities Visited · \(viewModel.visitedCities.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("InkBrown").opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.visitedCities, id: \.self) { city in
                            // Tapping the chip flies to that city on the map
                            StampChip(
                                city: city,
                                hasPin: annotations.contains(where: {
                                    $0.postcard.cityName.lowercased() == city.lowercased()
                                }),
                                isSelected: selectedAnnotation?.postcard.cityName.lowercased() == city.lowercased()
                            )
                            .onTapGesture {
                                flyToCity(city)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("ParchmentBG"))
                .shadow(color: .black.opacity(0.1), radius: 20, y: -4)
        )
    }
}

// MARK: - Pin view

struct PinView: View {
    let postcard: Postcard
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color("InkBrown") : Color("AccentTan"))
                    .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                if let image = UIImage(data: postcard.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: isSelected ? 36 : 26, height: isSelected ? 36 : 26)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: isSelected ? 16 : 12))
                        .foregroundColor(.white)
                }
            }
            Triangle()
                .fill(isSelected ? Color("InkBrown") : Color("AccentTan"))
                .frame(width: 10, height: 7)
        }
        .animation(.spring(), value: isSelected)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

// MARK: - Pin detail card

struct PinDetailCard: View {
    let postcard: Postcard
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if let image = UIImage(data: postcard.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 78, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(postcard.cityName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color("InkBrown"))
                if let weather = postcard.weatherDescription {
                    Text(weather.capitalized)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color("AccentTan"))
                }
                Text(postcard.dateCreated, style: .date)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color("InkBrown").opacity(0.35))
                Text(postcard.message)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color("InkBrown").opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color("InkBrown").opacity(0.25))
                    .font(.title3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("ParchmentBG"))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
        )
    }
}

// MARK: - Stamp chip
// hasPin = this city has GPS coords and shows on the map
// isSelected = this city's pin is currently selected

struct StampChip: View {
    let city: String
    let hasPin: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [5])
                    )
                    .foregroundColor(
                        isSelected ? Color("InkBrown") : Color("AccentTan").opacity(0.5)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected
                                  ? Color("AccentTan").opacity(0.15)
                                  : Color.clear)
                    )
                    .frame(width: 64, height: 64)

                VStack(spacing: 2) {
                    Text("🌊").font(.system(size: 24))
                    // Small dot shows it has a map pin
                    if hasPin {
                        Circle()
                            .fill(isSelected ? Color("InkBrown") : Color("AccentTan"))
                            .frame(width: 5, height: 5)
                    }
                }
            }
            Text(city)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected
                                 ? Color("InkBrown")
                                 : Color("InkBrown").opacity(0.65))
                .lineLimit(1)
                .frame(maxWidth: 70)
        }
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
